Bson = require 'bson'
Express = require 'express'
Path = require 'path'
spawn = require('child_process').spawn

ServerError = require '../../shared/scripts/server-error.coffee'
Daylite = require '../../shared/scripts/daylite.coffee'

AppCatalog = require '../../shared/scripts/app-catalog.coffee'
Directory = require AppCatalog.catalog['Host Filesystem'].path + '/directory.coffee'
HostFileSystem = require AppCatalog.catalog['Host Filesystem'].path + '/host-fs.coffee'
TargetApp = AppCatalog.catalog['Target information'].get_instance()
Workspace = require AppCatalog.catalog['Programs'].path +  '/workspace.coffee'

events = AppCatalog.catalog['Runner'].event_groups.runner_events.events

# information about the program which is currently running
class RunningProgram
  constructor: (@resource) ->

# the currently runned program
running = null

# the socket.io namespace
namespace = null

client = null

child_env = Object.create(process.env)
if TargetApp.platform is TargetApp.supported_platforms.WINDOWS_PC
  # assume that the install prefix of the kipr libraries is <harrogate>/../prefix/usr
  bin_dir = Path.resolve Path.resolve __dirname, '..', '..', '..' , 'prefix', 'usr', 'bin'
  child_env.PATH += Path.delimiter + bin_dir

start_program = ->
  if running?.resource?
    process = spawn "#{running.resource.bin_directory.path}/#{running.resource.name}", [], env: child_env

    process.stdout.on 'data', (data) ->
      namespace.emit events.stdout.id, data.toString('utf8')
      return
    process.stderr.on 'data', (data) ->
      namespace.emit events.stderr.id, data.toString('utf8')
      return
    process.on 'exit', (code) ->
      namespace.emit events.stdout.id, "Program exited with code #{code}"
      running = null
      return

    setTimeout (->
      client = Daylite.connect()
      if client?
        buffer = null
        client.on 'data', (data) ->

          # append data
          buffer = if buffer then Buffer.concat [buffer, data] else data
          # how much data do we expect?
          packet_size = buffer.readInt32LE 0, 4


          # if we gont enough
          if buffer.length >= packet_size
            packet_data = buffer.slice 0, packet_size

            # emit the frame
            doc = Bson.BSONPure.BSON.deserialize packet_data
            msg = 
              width: doc.msg.width
              height: doc.msg.height
              data: doc.msg.data.toString('base64')

            namespace.emit events.frame.id, msg

            if buffer.length isnt packet_size
              buffer = buffer.slice packet_size
            else
              buffer = null

          return
        client.on 'close', ->
          console.log 'close'
      ), 1000
  return

# the runner router
router = Express.Router()

# get information about the currently running program
router.get '/current', (request, response, next) ->
  response.writeHead 200, { 'Content-Type': 'application/json' }
  return response.end "#{JSON.stringify(running: running)}", 'utf8'

# get information about the currently running program
router.post '/', (request, response, next) ->
  # Validate the project name
  if not request.body.name?
      response.writeHead 422, { 'Content-Type': 'application/json' }
      return response.end "#{JSON.stringify(error: 'Parameter \'name\' missing')}", 'utf8'

  ws_resource = null

  # Create the ws resource
  HostFileSystem.open request.logged_in_user.preferences.workspace.path
  .then (ws_directory) ->
    # return 400 if it is a file
    if ws_directory not instanceof Directory
      throw new ServerError 400, ws_directory.path + ' is a file'

    ws_resource = new Workspace ws_directory

    # validate it
    return ws_resource.is_valid()
  .then (valid) ->
    if not valid
      throw new ServerError 400, ws_resource.ws_directory.path + ' is not a valid workspace'

    # and attach it to the request object
    return ws_resource.get_projects()
  .then (project_resources) ->

    # search for project.name is request.params.project
    project_resource = (project_resource for project_resource in project_resources when project_resource.name is request.body.name)[0]

    # did we found a project?
    if not project_resource?
        throw new ServerError 404, 'Project ' + request.body.name + ' does not exists'
    else
      if running?
        throw new ServerError 409, request.body.name + ' is already running'

      running = new RunningProgram project_resource
      start_program()

      response.writeHead 201, { 'Content-Type': 'application/json' }
      return response.end "#{JSON.stringify(running: running)}", 'utf8'
  .catch (e) ->
    if e instanceof ServerError
      response.writeHead e.code, { 'Content-Type': 'application/javascript' }
      return response.end "#{JSON.stringify(error: e.message)}", 'utf8'
    else
      next e
  .done()
  return

# get information about the currently running program
router.delete '/current', (request, response, next) ->
  response.writeHead 200, { 'Content-Type': 'application/json' }
  return response.end "#{JSON.stringify(running: running)}", 'utf8'

runner_on_connection = (socket) ->
  socket.on events.gui_input.id, (data) ->
    if client? and data.mouse?
      doc =
        topic: '/aurora/mouse'
        msg: data.mouse

      client.write Bson.BSONPure.BSON.serialize(doc, false, true, true)

    if client? and data.keyboard?
      doc =
        topic: '/aurora/key'
        msg: data.keyboard

      client.write Bson.BSONPure.BSON.serialize(doc, false, true, true)

module.exports =
  event_init: (event_group_name, ns) ->
    namespace = ns

    namespace.on 'connection', runner_on_connection
    return

  init: (app) =>
    # add the router
    app.web_api.run['router'] = router
    return

  exec: ->
    return

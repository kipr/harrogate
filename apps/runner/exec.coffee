if process.env.CROSSCOMPILE
  Daylite = require 'node-daylite'
Express = require 'express'
Path = require 'path'
spawn = require('child_process').spawn

ServerError = require_harrogate_module '/shared/scripts/server-error.coffee'

AppCatalog = require_harrogate_module '/shared/scripts/app-catalog.coffee'
Config = require_harrogate_module 'config.coffee'
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
running_process = null

# the socket.io namespace
namespace = null

client = null

#child_env = Object.create(process.env)
#if TargetApp.platform is TargetApp.supported_platforms.WINDOWS_PC
#  child_env.Path += Path.delimiter + "#{Config.ext_deps.bin_path}"
#else
#  child_env.DYLD_LIBRARY_PATH += Path.delimiter + "#{Config.ext_deps.lib_path}"

latest_graphics_window_frame = null

start_program = ->
  if running?.resource?
    latest_graphics_window_frame = null

    # TODO: change me!!
    # Create data directory
    running.resource.data_directory.create()
    .finally ->

      namespace.emit events.starting.id, running.resource.name

      running_process = spawn running.resource.binary.path, [], {
        # env: child_env
        cwd: Path.resolve running.resource.data_directory.path
      }

      running_process.on 'error', (data) ->
        console.log "Could not spawn #{running.resource.binary.path}!! Error details: #{JSON.stringify(error: data)}"
        namespace.emit events.stderr.id, "Program crashed!\n\nError details:\n#{JSON.stringify(error: data,null,'\t')}"
        namespace.emit events.ended.id
        stop_program()
        return

      running_process.stdout.on 'data', (data) ->
        namespace.emit events.stdout.id, data.toString('utf8')
        return

      running_process.stderr.on 'data', (data) ->
        namespace.emit events.stderr.id, data.toString('utf8')
        return

      running_process.on 'exit', (code) ->
        namespace.emit events.stdout.id, "Program exited with code #{code}"
        namespace.emit events.ended.id
        stop_program()
        return

      connect_to_daylite = ->
        if running_process?
          client = new Daylite.DayliteClient

          client.on 'error', (error) ->
            setTimeout connect_to_daylite, 100
            return

          client.join_daylite 8374

          client.subscribe '/aurora/frame', (msg) ->
  
            console.log "GOT MESSAGE"

            repacked_msg =
              width: msg.width
              height: msg.height
              #data: msg.data.toString('base64')

            latest_graphics_window_frame = msg.data

            namespace.emit events.frame.id, repacked_msg
            return

          client.on 'close', ->
            client = null
            return

      setTimeout connect_to_daylite, 100
  return

stop_program = -> 
  if running_process?
    running_process.kill()
    running_process = null

  if running?
    running = null

  return

# the runner router
router = Express.Router()

# get information about the currently running program
router.get '/current', (request, response, next) ->
  response.writeHead 200, { 'Content-Type': 'application/json' }
  response.end "#{JSON.stringify(running: running)}", 'utf8'

# get the current graphics window
router.get '/current/graphics', (request, response, next) ->
  if latest_graphics_window_frame?
    response.setHeader "Cache-Control", "no-cache, no-store, must-revalidate"
    response.setHeader "Pragma", "no-cache"
    response.setHeader "Expires", "0"
    response.writeHead 200, { 'Content-Type': 'image/png' }
    response.end latest_graphics_window_frame, 'binary'
  else
    response.setHeader "Cache-Control", "no-cache, no-store, must-revalidate"
    response.setHeader "Pragma", "no-cache"
    response.setHeader "Expires", "0"
    response.writeHead 404, { 'Content-Type': 'application/json' }
    response.end "#{JSON.stringify(error: 'No program is running')}", 'utf8'

# get information about the currently running program
router.post '/', (request, response, next) ->
  # Validate the project name
  if not request.body.name?
      response.writeHead 422, { 'Content-Type': 'application/json' }
      response.end "#{JSON.stringify(error: 'Parameter \'name\' missing')}", 'utf8'

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
      response.end "#{JSON.stringify(running: running)}", 'utf8'
  .catch (e) ->
    if e instanceof ServerError
      response.writeHead e.code, { 'Content-Type': 'application/javascript' }
      response.end "#{JSON.stringify(error: e.message)}", 'utf8'
    else
      next e
  .done()
  return

# stop the currently running program
router.delete '/current', (request, response, next) ->
  stop_program()
  response.writeHead 200, { 'Content-Type': 'application/json' }
  response.end "#{JSON.stringify(running: running)}", 'utf8'

runner_on_connection = (socket) ->

  socket.on events.gui_input.id, (data) ->
    if client? and data.mouse?
      client.publish '/aurora/mouse', data.mouse

    if client? and data.keyboard?
      client.publish '/aurora/key', data.keyboard
    return

  socket.on events.stdin.id, (data) ->
    if running_process?
      running_process.stdin.write data + '\n'
    return

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

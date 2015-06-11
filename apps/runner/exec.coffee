Express = require 'express'
spawn = require('child_process').spawn

ServerError = require '../../shared/scripts/server-error.coffee'

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

start_program = ->
  if running?.resource?
    process = spawn "#{running.resource.bin_directory.path}/#{running.resource.name}"

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

module.exports =
  event_init: (event_group_name, ns) ->
    namespace = ns
    return

  init: (app) =>
    # add the router
    app.web_api.run['router'] = router
    return

  exec: ->
    return

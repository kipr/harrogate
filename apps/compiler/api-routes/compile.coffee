Express = require 'express'

ServerError = require_harrogate_module '/shared/scripts/server-error.coffee'

AppCatalog = require_harrogate_module '/shared/scripts/app-catalog.coffee'
Directory = require AppCatalog.catalog['Host Filesystem'].path + '/directory.coffee'
HostFileSystem = require AppCatalog.catalog['Host Filesystem'].path + '/host-fs.coffee'
TargetApp = AppCatalog.catalog['Target information'].get_instance()
Workspace = require AppCatalog.catalog['Programs'].path +  '/workspace.coffee'

# get the compilation environments
if TargetApp.platform is TargetApp.supported_platforms.WINDOWS_PC
  compilation_environment = require '../compilation-environments/c/mingw.coffee'
else
  compilation_environment = require '../compilation-environments/c/gcc.coffee'

# the compiler router
router = Express.Router()

# get information about the currently running program
router.post '/', (request, response, next) ->
  # Validate the project name
  if not request.body.name?
    next new ServerError(422, 'Parameter \'name\' missing')
    return

  ws_resource = null
  project_resource = null

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

    # delete the bin folder if it is existing
    return ws_resource.bin_directory.get_child project_resource.name

  .then ( (child) ->
    # bin folder exists, delete it
    return child.remove()
    
  ), ->
    return # No child exist, continue

  .then ->
    # create the bin folder
    return ws_resource.bin_directory.create_subdirectory project_resource.name

  .then ->

    project_resource.get_representation(false)
      .then (project_details) ->
        language = project_details.parameters.language

        if (language.toLowerCase() == 'c')
          if TargetApp.platform is TargetApp.supported_platforms.WINDOWS_PC
            compilation_environment = require '../compilation-environments/c/mingw.coffee'
          else
            compilation_environment = require '../compilation-environments/c/gcc.coffee'
        else if (language.toLowerCase() == 'python')
          compilation_environment = require '../compilation-environments/python/python.coffee'

        compilation_environment.compile project_resource, (error, stdout, stderr) ->
          result = {stdout: stdout, stderr: stderr, error: error}
          response.setHeader 'Cache-Control', 'no-cache, no-store, must-revalidate'
          response.setHeader 'Pragma', 'no-cache'
          response.setHeader 'Expires', '0'
          response.writeHead 200, { 'Content-Type': 'application/json' }
          response.end "#{JSON.stringify(result: result)}", 'utf8'
          return

  .catch (error) ->
    next error
    return

  .done()
  return

# export the router object
module.exports = router

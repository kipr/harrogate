Express = require 'express'
exec = require('child_process').exec
Path = require 'path'

ServerError = require '../../shared/scripts/server-error.coffee'

AppCatalog = require '../../shared/scripts/app-catalog.coffee'
Directory = require AppCatalog.catalog['Host Filesystem'].path + '/directory.coffee'
HostFileSystem = require AppCatalog.catalog['Host Filesystem'].path + '/host-fs.coffee'
TargetApp = AppCatalog.catalog['Target information'].get_instance()
Workspace = require AppCatalog.catalog['Programs'].path +  '/workspace.coffee'

# get available compilation environments
class VisualStudio12CompilationEnvironment
  @compile: (project_resource, cb) ->
    project_resource.src_directory.is_valid()
    .then (valid) ->

      if not valid
        throw new ServerError 404, 'Project ' + project_resource.name + ' does not contain any source files'

      return project_resource.src_directory.get_children()
    .then (src_files) ->
      cl_cmd = "/I\"#{project_resource.include_directory.path}\"
                /Fe\"#{project_resource.bin_directory.path}\\#{project_resource.name}\" "
      for src in src_files
        cl_cmd += "\"#{src.path}\" "

      exec 'vs12_compiler.bat ' + cl_cmd, {cwd: __dirname}, cb
      return
    .catch (e) ->
      console.log e
    .done()
    return


class GCCCompilationEnvironment
  @compile: (project_resource, cb) ->
    project_resource.src_directory.is_valid()
    .then (valid) ->

      if not valid
        throw new ServerError 404, 'Project ' + project_resource.name + ' does not contain any source files'

      return project_resource.src_directory.get_children()
    .then (src_files) ->
      gcc_cmd = "gcc -I#{project_resource.include_directory.path} -Wall -o #{project_resource.bin_directory.path}/#{project_resource.name} "
      for src in src_files
        if Path.basename(src.path).charAt(0) isnt '.'
          gcc_cmd += src.path + ' '
      
      exec gcc_cmd, cb
      return
    .catch (e) ->
      console.log e
    .done()
    return

# the compiler router
router = Express.Router()

# get information about the currently running program
router.post '/', (request, response, next) ->
  # Validate the project name
  if not request.body.name?
      response.writeHead 422, { 'Content-Type': 'application/json' }
      return response.end "#{JSON.stringify(error: 'Parameter \'name\' missing')}", 'utf8'

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

    # create the bin folder
    return ws_resource.bin_directory.create_subdirectory project_resource.name
    .catch ->
      return # ignore file exist error
    .finally ->
      if TargetApp.platform is TargetApp.supported_platforms.WINDOWS_PC
        compile = VisualStudio12CompilationEnvironment.compile
      else
        compile = GCCCompilationEnvironment.compile

      compile project_resource, (error, stdout, stderr) ->
        result = {error: error, stdout: stdout, stderr: stderr}
        response.writeHead 200, { 'Content-Type': 'application/json' }
        return response.end "#{JSON.stringify(result: result)}", 'utf8'

      return
  .catch (e) ->
    if e instanceof ServerError
      response.writeHead e.code, { 'Content-Type': 'application/javascript' }
      return response.end "#{JSON.stringify(error: e.message)}", 'utf8'
    else
      next e
  .done()
  return

module.exports =
  init: (app) =>
    # add the router
    app.web_api.run['router'] = router
    return

  exec: ->
    return

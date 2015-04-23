Url = require 'url'
FS = require 'fs'
Path = require 'path'
Q = require 'q'
Express = require 'Express'
AppCatalog = require '../../shared/scripts/app-catalog.coffee'
TargetApp = AppCatalog.catalog['Target information'].get_instance()
FsApp = AppCatalog.catalog['Host Filesystem'].get_instance()
FsResourceFactory = FsApp.FsResourceFactory
FsFileResource = FsResourceFactory.FsFileResource
FsDirectoryResource = FsResourceFactory.FsDirectoryResource
WorkspaceResourceFactory = require './workspace-resource-factory.coffee'
ServerError = require '../../shared/scripts/server-error.coffee'

AppManifest = require './manifest.json'


# the fs router
router = Express.Router()

# default workspace path
default_base_fs_resource = undefined
switch TargetApp.platform
  when TargetApp.supported_platforms.WINDOWS_PC
    path = Path.join FsApp.home_folder.path, 'Documents', 'KISS_Projects'
    default_base_fs_resource = WorkspaceResourceFactory.create AppManifest.web_api.projects.uri, FsDirectoryResource.create_from_path(path)
  # TODO: Add it for other platforms

class ProgramsApp
  init: (app) ->
    # add the home folder and the router
    app.web_api.projects['router'] = router

  exec: ->

# create the app object
programs_app = new ProgramsApp

# '/' is relative to <app_manifest>.web_api.projects.uri
router.use '/', (request, response, next) ->
  # Was a workspace fs uri provided?
  ws_uri = Url.parse(request.url, true).query['ws_uri']
  if ws_uri?
    ws_resource = WorkspaceResourceFactory.create request.baseUrl, new FsDirectoryResource(ws_uri)
  else # use default resource
    ws_resource = default_base_fs_resource

  # validate workspace path (TODO: Change me!!)
  try
    stats = FS.statSync ws_resource.base_fs_resource.path
  catch err
    if err.code is 'ENOENT'
      err_resp =
        error: 'Unable to open workspace'
        workspace_uri: ws_resource.base_fs_resource.uri
        reason: 'No such file or directory'

      response.writeHead 404, { 'Content-Type': 'application/json' }
      return response.end "#{JSON.stringify(err_resp)}", 'utf8'

    else # something unexpected happened
      err_resp =
        error: 'Unable to open workspace'
        workspace_uri: ws_resource.base_fs_resource.uri
        reason: 'Unable to open ' + ws_resource.base_fs_resource.name

      response.writeHead 500, { 'Content-Type': 'application/json' }
      return response.end "#{JSON.stringify(err_resp)}", 'utf8'

  # return an error if it is not a directory
  if ws_resource.base_fs_resource not instanceof FsResourceFactory.FsDirectoryResource
    err_resp =
      error: 'Unable to open workspace'
      workspace_uri: ws_resource.base_fs_resource.uri
      reason: ws_resource.base_fs_resource.name + ' is not a directory'

    response.writeHead 400, { 'Content-Type': 'application/json' }
    return response.end "#{JSON.stringify(err_resp)}", 'utf8'

  # store resource and continue
  request.ws_resource = ws_resource
  next()
  return

router.get '/', (request, response, next) ->
  request.ws_resource.get_representation()
  .then (representation) ->
    callback = Url.parse(request.url, true).query['callback']
    # should we return JSON or JSONP (callback defined)?
    if callback?
      response.writeHead 200, { 'Content-Type': 'application/javascript' }
      return response.end "#{callback}(#{JSON.stringify(representation)})", 'utf8'
    else
      response.writeHead 200, { 'Content-Type': 'application/json' }
      return response.end "#{JSON.stringify(representation)}", 'utf8'
  .catch (e) ->
    if e instanceof ServerError
      response.writeHead e.code, { 'Content-Type': 'application/javascript' }
      return response.end "#{JSON.stringify(error: e.message)}", 'utf8'
    else
      next e
  .done()
  return

router.post '/', (request, response, next) ->
  # We only support application/json
  if request.headers['content-type'] isnt 'application/json'
    response.writeHead 415, { 'Content-Type': 'application/json' }
    return response.end "#{JSON.stringify(error: 'Only content-type application/json supported')}", 'utf8'

  # Validate the name
  if not request.body.name?
      response.writeHead 422, { 'Content-Type': 'application/json' }
      return response.end "#{JSON.stringify(error: 'Parameter \'name\' missing')}", 'utf8'

  # Validate the type
  if not request.body.language?
    response.writeHead 422, { 'Content-Type': 'application/json' }
    return response.end "#{JSON.stringify(error: 'Parameter \'language\' missing')}", 'utf8'

  request.ws_resource.create_project request.body.name, request.body.language
  .then (resource) ->
    response.writeHead 201, { 'Location': "#{resource.uri}" }
    return response.end()
  .catch (e) ->
    if e instanceof ServerError
      response.writeHead e.code, { 'Content-Type': 'application/javascript' }
      return response.end "#{JSON.stringify(error: e.message)}", 'utf8'
    else
      next e
  .done()
  return

router.get '/:project', (request, response, next) ->
  request.ws_resource.get_projects()
  .then (project_resources) ->

    # search for project.name is request.params.project
    project_resource = (project_resource for project_resource in project_resources when project_resource.name is request.params.project)[0]

    # did we found a project?
    if not project_resource?
        throw new ServerError 404, 'Project ' + project_resource.name + ' does not exists'
    else
      project_resource.get_representation()
      .then (representation) ->
        callback = Url.parse(request.url, true).query['callback']
        # should we return JSON or JSONP (callback defined)?
        if callback?
          response.writeHead 200, { 'Content-Type': 'application/javascript' }
          return response.end "#{callback}(#{JSON.stringify(representation)})", 'utf8'
        else
          response.writeHead 200, { 'Content-Type': 'application/json' }
          return response.end "#{JSON.stringify(representation)}", 'utf8'
  .catch (e) ->
    if e instanceof ServerError
      response.writeHead e.code, { 'Content-Type': 'application/javascript' }
      return response.end "#{JSON.stringify(error: e.message)}", 'utf8'
    else
      next e
  .done()
  return

# return unsupported method for anything not handlet yet
router.use '/', (request, response, next) ->
  err_resp =
    error: 'Unable to handle request'
    reason: request.method + ' not allowed'

  response.writeHead 405, { 'Content-Type': 'application/json' }
  return response.end "#{JSON.stringify(err_resp)}", 'utf8'

module.exports = programs_app
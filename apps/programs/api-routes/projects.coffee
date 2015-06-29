Express = require 'express'
Url = require 'url'

AppCatalog = require '../../../shared/scripts/app-catalog.coffee'
Project = require '../project.coffee'
ServerError = require '../../../shared/scripts/server-error.coffee'
Workspace = require '../workspace.coffee'

Directory = require AppCatalog.catalog['Host Filesystem'].path + '/directory.coffee'
HostFileSystem = require AppCatalog.catalog['Host Filesystem'].path + '/host-fs.coffee'

# the fs router
router = Express.Router()

# '/' is relative to <manifest>.web_api.projects.uri
router.use '/', (request, response, next) ->
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
    request.ws_resource = ws_resource
    next()
  # could not create the ws resource (wrong path)
  .catch (e) ->
    if e instanceof ServerError
      response.writeHead e.code, { 'Content-Type': 'application/javascript' }
      return response.end "#{JSON.stringify(error: e.message)}", 'utf8'
    else
      next e
  .done()
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
  if not /application\/json/i.test request.headers['content-type']
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
        throw new ServerError 404, 'Project ' + request.params.project + ' does not exists'
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

module.exports = router

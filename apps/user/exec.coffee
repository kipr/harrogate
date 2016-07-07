Express = require 'express'
Url = require 'url'

AppCatalog = require_harrogate_module '/shared/scripts/app-catalog.js'
ServerError = require_harrogate_module '/shared/scripts/server-error.js'
UserManager = require_harrogate_module '/shared/scripts/user-manager.coffee'
UserResource = require './rest-resources/user-resource.coffee'

AppManifest = require './manifest.json'

Directory = require AppCatalog.catalog['Host Filesystem'].path + '/directory.js'

# the fs router
router = Express.Router()

# '/' is relative to <manifest>.web_api.user.uri
router.get '/current', (request, response, next) ->
  if request.logged_in_user?
    user_resource = new UserResource(request.logged_in_user)
    user_resource.get_representation()
    .then (representation) ->
      response.setHeader 'Cache-Control', 'no-cache, no-store, must-revalidate'
      response.setHeader 'Pragma', 'no-cache'
      response.setHeader 'Expires', '0'
      response.writeHead 200, { 'Content-Type': 'application/json' }
      return response.end "#{JSON.stringify(representation)}", 'utf8'
    .catch (e) ->
      if e instanceof ServerError
        response.writeHead e.code, { 'Content-Type': 'application/javascript' }
        return response.end "#{JSON.stringify(error: e.message)}", 'utf8'
      else
        next e
    .done()
  else
    response.writeHead 404, { 'Content-Type': 'application/json' }
    return response.end "#{JSON.stringify(error: 'No user is logged in')}", 'utf8'

router.get '/', (request, response, next) ->
  representation =
      links:
        self:
          href: AppManifest.web_api.users.uri

  if request.logged_in_user?
    representation.links.current = 
      login: request.logged_in_user.login
      href: request.logged_in_user.uri

  for user_name, user of UserManager.users
    if not representation.links.users?
      representation.links.users = []

    user_resource = new UserResource user
    representation.links.users.push { login: user_resource.user.login, href: user_resource.url }

  response.setHeader 'Cache-Control', 'no-cache, no-store, must-revalidate'
  response.setHeader 'Pragma', 'no-cache'
  response.setHeader 'Expires', '0'
  response.writeHead 200, { 'Content-Type': 'application/json' }
  return response.end "#{JSON.stringify(representation)}", 'utf8'

router.put '/:user', (request, response, next) ->

  # We only support application/json
  if not /application\/json/i.test request.headers['content-type']
    next new ServerError(415, 'Only content-type application/json supported')
    return

  # did a user with the given name exists
  if not UserManager.users[request.params.user]?
      throw new ServerError 404, 'User ' + request.params.user + ' does not exists'

  # TODO: Make this more generic. Currently one the workspace path is supported

  # Validate the type
  if not request.body.preferences?.workspace?.path?
    response.writeHead 422, { 'Content-Type': 'application/json' }
    return response.end "#{JSON.stringify(error: 'Parameter \'preferences.workspace.path\' missing')}", 'utf8'

  # Check if the workspace directory exists
  ws_dir = Directory.create_from_path request.body.preferences.workspace.path

  ws_dir.is_valid()
  .then (valid) =>
    if not valid
      next new ServerError(404, 'Workspace path is not a valid directory')
      return

    UserManager.update_user request.params.user, request.body

    response.writeHead 204
    response.end()
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
    app.web_api.users['router'] = router
    return

  exec: ->

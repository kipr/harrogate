url = require 'url'
fs = require 'fs'
path = require 'path'
express = require 'express'
app_manifest = require './manifest.json'
app_catalog = require '../../shared/scripts/app-catalog.coffee'
target_app = app_catalog.catalog['Target information'].get_instance()
FsResourceFactory = require './fs-resource-factory.coffee'
ServerError = require '../../shared/scripts/server-error.coffee'

# the fs router
router = express.Router()

class FsApp
  constructor: ->
    @home_folder = FsResourceFactory.FsDirectoryResource.create_from_path process.env[ if target_app.platform is target_app.supported_platforms.WINDOWS_PC then 'USERPROFILE' else 'HOME' ]

  # expose the fs resources
  FsResourceFactory: FsResourceFactory

  init: (app) =>
    # add the home folder and the router
    app.web_api.fs['home_uri'] = @home_folder.uri
    app.web_api.fs['router'] = router

  exec: ->

# create the app object
fs_app = new FsApp

# '/' is relative to <app_manifest>.web_api.fs.uri
router.use '/', (request, response, next) ->
  # Create the fs resource
  FsResourceFactory.create_from_uri url.parse(request.originalUrl, true).pathname
   # store it and continue
  .then (value) ->
    request.fs_resource = value
    next()
  # could not create the fs resource (wrong path)
  .catch (e) ->
    if e instanceof ServerError
      response.writeHead e.code, { 'Content-Type': 'application/javascript' }
      return response.end "#{JSON.stringify(error: e.message)}", 'utf8'
    else
      next e
  .done()
  return

router.get '/*', (request, response, next) ->
  # the the FS path
  fs_path = request.fs_resource.path

  # is the raw file or the JSON object requested?
  response_mode = url.parse(request.url, true).query['mode']
  if response_mode? and response_mode is 'raw'
    response.download fs_path

  else
    request.fs_resource.get_representation()
    .then (representation) ->
      callback = url.parse(request.url, true).query['callback']
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

router.post '/*', (request, response, next) ->
  # We only support application/json
  if request.headers['content-type'] isnt 'application/json'
    response.writeHead 415, { 'Content-Type': 'application/json' }
    return response.end "#{JSON.stringify(error: 'Only content-type application/json supported')}", 'utf8'

  # Check if the uri points to a directory
  if request.fs_resource not instanceof FsResourceFactory.FsDirectoryResource
    response.writeHead 400, { 'Content-Type': 'application/json' }
    return response.end "#{JSON.stringify(error: request.fs_resource.path + ' is not a directory')}", 'utf8'

  # Validate the name
  if not request.body.name?
      response.writeHead 422, { 'Content-Type': 'application/json' }
      return response.end "#{JSON.stringify(error: 'Parameter \'name\' missing')}", 'utf8'

  # Validate the type
  if not request.body.type?
    response.writeHead 422, { 'Content-Type': 'application/json' }
    return response.end "#{JSON.stringify(error: 'Parameter \'type\' missing')}", 'utf8'
  if request.body.type not in ['file', 'directory']
    response.writeHead 422, { 'Content-Type': 'application/json' }
    return response.end "#{JSON.stringify(error: 'Invalid value for parameter \'type\'')}", 'utf8'

  if request.body.type is 'directory'
    resource_promise = request.fs_resource.create_subdirectory request.body.name
  else # request.body.type is 'file'
    encoding = if request.body.encoding? then request.body.encoding else 'ascii'
    content = if request.body.content? then new Buffer(request.body.content, 'base64').toString(encoding) else ''
    resource_promise = request.fs_resource.create_file request.body.name, content, encoding

  resource_promise
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

router.put '/*', (request, response) ->
  # We only support application/json
  if request.headers['content-type'] isnt 'application/json'
    response.writeHead 415, { 'Content-Type': 'application/json' }
    return response.end "#{JSON.stringify(error: 'Only content-type application/json supported')}", 'utf8'

  # Check if the uri points to a directory
  if request.fs_resource not instanceof FsResourceFactory.FsFileResource
    response.writeHead 400, { 'Content-Type': 'application/json' }
    return response.end "#{JSON.stringify(error: request.fs_resource.path + ' is not a file')}", 'utf8'

  request.fs_resource.write request.body.content, request.body.encoding
  .then () ->
    response.writeHead 204
    return response.end()
  .catch (e) ->
    if e instanceof ServerError
      response.writeHead e.code, { 'Content-Type': 'application/javascript' }
      return response.end "#{JSON.stringify(error: e.message)}", 'utf8'
    else
      next e
  .done()
  return

router.delete '/*', (request, response) ->
  request.fs_resource.remove()
  .then () ->
    response.writeHead 204
    return response.end()
  .catch (err) ->
    if err.code is 'ENOTEMPTY'
      response.writeHead 403, { 'Content-Type': 'application/json' }
      return response.end "#{JSON.stringify(error: request.fs_resource.name + ' is not empty')}", 'utf8'
    else if err.code is 'ENOENT'
      response.writeHead 404, { 'Content-Type': 'application/json' }
      return response.end "#{JSON.stringify(error: 'No such file or directory')}", 'utf8'
    else  # the file exists but we cannot delete it...
      response.writeHead 403, { 'Content-Type': 'application/json' }
      return response.end "#{JSON.stringify(error: 'Unable to delete ' + request.fs_resource.name)}", 'utf8'
  .done()
  return

# return unsupported method for anything not handlet yet
router.use '/', (request, response, next) ->
  err_resp =
    error: 'Unable to handle request'
    reason: request.method + ' not allowed'

  response.writeHead 405, { 'Content-Type': 'application/json' }
  return response.end "#{JSON.stringify(err_resp)}", 'utf8'

# export the app object
module.exports = fs_app
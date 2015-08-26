Express = require 'express'
Url = require 'url'

Directory = require '../directory.coffee'
File = require '../file.coffee'
HostFileSystem = require '../host-fs.coffee'
ServerError = require_harrogate_module '/shared/scripts/server-error.coffee'

# the fs router
router = Express.Router()

# '/' is relative to <manifest>.web_api.fs.uri
router.use '/', (request, response, next) ->
  # Create the fs resource
  HostFileSystem.open uri: Url.parse(request.originalUrl, true).pathname

   # store it and continue
  .then (value) ->
    request.fs_resource = value
    next()
    return

  # could not create the fs resource (wrong path)
  .catch (error) ->
    next error
    return

  .done()
  return

router.get '/*', (request, response, next) ->
  # the the FS path
  fs_path = request.fs_resource.path

  # is the raw file or the JSON object requested?
  response_mode = Url.parse(request.url, true).query['mode']
  if response_mode? and response_mode is 'raw'
    response.download fs_path

  else
    request.fs_resource.get_representation()

    .then (representation) ->
      response.setHeader 'Cache-Control', 'no-cache, no-store, must-revalidate'
      response.setHeader 'Pragma', 'no-cache'
      response.setHeader 'Expires', '0'
      response.writeHead 200, { 'Content-Type': 'application/json' }
      response.end "#{JSON.stringify(representation)}", 'utf8'
      return

    .catch (error) ->
      next error
      return

    .done()
  return

router.post '/*', (request, response, next) ->
  # We only support application/json
  if not /application\/json/i.test request.headers['content-type']
    next new ServerError(415, 'Only content-type application/json supported')
    return

  # Check if the uri points to a directory
  if request.fs_resource not instanceof Directory
    next new ServerError(400, request.fs_resource.path + ' is not a directory')
    return

  # Validate the name
  if not request.body.name?
    next new ServerError(422, 'Parameter \'name\' missing')
    return

  # Validate the type
  if not request.body.type?
    next new ServerError(422, 'Parameter \'type\' missing')
    return

  if request.body.type not in ['file', 'directory']
    next new ServerError(422, 'Invalid value for parameter \'type\'')
    return

  if request.body.type is 'directory'
    resource_promise = request.fs_resource.create_subdirectory request.body.name

  else # request.body.type is 'file'
    encoding = if request.body.encoding? then request.body.encoding else 'ascii'
    content = if request.body.content? then new Buffer(request.body.content, 'base64').toString(encoding) else ''
    resource_promise = request.fs_resource.create_file request.body.name, content, encoding

  resource_promise.then (resource) ->
    response.writeHead 201, { 'Location': "#{resource.uri}" }
    response.end()
    return

  .catch (error) ->
    next error
    return

  .done()
  return

router.put '/*', (request, response) ->
  # We only support application/json
  if not /application\/json/i.test request.headers['content-type']
    next new ServerError(415, 'Only content-type application/json supported')
    return

  # Check if the uri points to a directory
  if request.fs_resource not instanceof File
    next new ServerError(400, request.fs_resource.path + ' is not a file')
    return

  # write the content to the file
  encoding = if request.body.encoding? then request.body.encoding else 'ascii'
  content = if request.body.content? then new Buffer(request.body.content, 'base64').toString(encoding) else ''
  request.fs_resource.write content, encoding

  .then ->
    response.writeHead 204
    response.end()
    return

  .catch (error) ->
    next error
    return

  .done()
  return

router.delete '/*', (request, response) ->
  # delete the fs resource
  request.fs_resource.remove()

  .then ->
    response.writeHead 204
    response.end()
    return

  .catch (err) ->
    if err.code is 'ENOTEMPTY'
      next new ServerError(403, request.fs_resource.name + ' is not empty')
      return

    if err.code is 'ENOENT'
      next new ServerError(404, 'No such file or directory')
      return

    # the file exists but we cannot delete it...
    next new ServerError(403, 'Unable to delete ' + request.fs_resource.name)
    return

  .done()
  return

# export the router object
module.exports = router
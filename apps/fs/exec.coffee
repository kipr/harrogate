url = require 'url'
fs = require 'fs'
path = require 'path'
mime = require 'mime'
express = require 'express'
app_manifest = require './manifest.json'
app_catalog = require '../../shared/scripts/app-catalog.coffee'
target_app = app_catalog.catalog['Target information'].get_instance()

# the fs router
router = express.Router()

# get the drive letters
win_drive_letters = []
if target_app.platform is target_app.supported_platforms.WINDOWS_PC
  spawn = require('child_process').spawn
  list = spawn('cmd')
  list.stdout.on 'data', (data) ->
    data_str = '' + data
    matches = data_str.match /^(.:)(?!\S)/gm
    win_drive_letters = matches if matches?
    return
  list.stderr.on 'data', (data) ->
    console.log 'stderr: ' + data
    return
  list.on 'exit', (code) ->
    return
  list.stdin.write 'wmic logicaldisk get name\n'
  list.stdin.end()

class FsApp
  init: (app) ->
    # add the home folder and the router
    app.web_api.fs['home_uri'] = @get_home_uri()
    app.web_api.fs['router'] = router

  exec: ->

  uri_2_path: (uri, has_api_prefix = true) ->
    if has_api_prefix # uri = <app_manifest.web_api.fs.uri>/<fs_path>
      fs_path = uri.substr app_manifest.web_api.fs.uri.length
    else # uri = <fs_path>
      fs_path = uri

    # '/' --> os dependent path separator
    fs_path = fs_path.replace /(\/)/g, path.sep

    # For Windows '\C:' --> C:\
    if target_app.platform is target_app.supported_platforms.WINDOWS_PC
      fs_path = fs_path.substr 1
      if fs_path.slice(-1) is ':'
        fs_path = fs_path + path.sep

    return fs_path

  path_2_uri: (fs_path, add_api_prefix = true) ->
    # os dependent path separator --> '/'
    uri = fs_path.replace new RegExp('\\' + path.sep, 'g'), '/'

    # <fs_path>/ --> <fs_path>
    if uri.slice(-1) is '/'
      uri = uri.slice(0, -1)

    # For Windows 'C:' --> \C:
    if target_app.platform is target_app.supported_platforms.WINDOWS_PC
      uri = '/' + uri

    # <fs_path> --> <app_manifest.web_api.fs.uri>/<fs_path>
    if add_api_prefix
      uri = "#{app_manifest.web_api.fs.uri}" + uri

    return uri

  get_home_path: () ->
    return process.env[ if target_app.platform is target_app.supported_platforms.WINDOWS_PC then 'USERPROFILE' else 'HOME']

  get_home_uri: () =>
    return @path_2_uri @get_home_path()

# create the app object
fs_app = new FsApp

# '/' is relative to <app_manifest>.web_api.fs.uri
router.use '/', (request, response, next) ->
  # store the the FS path
  request.fs_path = fs_app.uri_2_path url.parse(request.url, true).pathname, false
  next()
  return

router.get '/*', (request, response) ->
  # the the FS path
  fs_path = request.fs_path

  # is the raw file or the JSON object requested?
  response_mode = url.parse(request.url, true).query['mode']
  if response_mode? and response_mode is 'raw'
    response.download fs_path

  else
    # Handle 'This PC'
    if target_app.platform is target_app.supported_platforms.WINDOWS_PC and fs_path is ''
      resp_obj =
        name: "This PC"
        type: 'Directory'
        links:
          self:
            href: '/api/fs/'
          childs: []

      for drive_letter in win_drive_letters
        child = 
          name: drive_letter + path.sep
          type: 'Directory'
          mime: mime.lookup drive_letter + path.sep
          path: drive_letter + path.sep
          href: '/api/fs/' + drive_letter # urlencode?

        resp_obj.links.childs.push child

    else
      # check if the path exists
      if not fs.existsSync fs_path
        response.writeHead 404, { 'Content-Type': 'application/json' }
        return response.end "#{JSON.stringify(error: fs_path + ': No such file or directory')}", 'utf8'

      # Create the response object
      resp_obj =
        name: if (fs_path.slice(-2) is (':' + path.sep)) then fs_path else path.basename fs_path
        type: 'Unknown'
        mime: mime.lookup fs_path
        path: fs_path
        links:
          self:
            href: request.originalUrl

      # get the parent
      parent_fs_path = path.dirname(fs_path)
      if parent_fs_path isnt fs_path
        resp_obj.links.parent =
            name: path.basename parent_fs_path
            type: 'Directory' # assume that the parent is always a directory
            mime: mime.lookup parent_fs_path
            path: parent_fs_path
            href: path.dirname request.originalUrl
      if target_app.platform is target_app.supported_platforms.WINDOWS_PC and fs_path.slice(-2) is (':' + path.sep)
        resp_obj.links.parent =
            name: "This PC"
            type: 'Directory'
            href: '/api/fs/'

      # get statistics
      stats = fs.statSync fs_path

      # list the files if it is a directory
      if stats.isDirectory()
        resp_obj.type = 'Directory'
        resp_obj.links.childs = []

        for filename in fs.readdirSync fs_path
          child = 
            name: filename
            type: 'Unknown'
            mime: mime.lookup fs_path + path.sep + filename
            path: fs_path + path.sep + filename
            href: request.originalUrl + '/' + filename # urlencode?

          try
            child_stats = fs.statSync child.path
            if child_stats.isDirectory()
              child.type = 'Directory'
            else if child_stats.isFile()
              child.type = 'File'
          catch
              child.type = 'Not Accessible'

          resp_obj.links.childs.push child

      # add the content if it is a file
      if stats.isFile()
          content = fs.readFileSync(fs_path)
          resp_obj.content = fs.readFileSync(fs_path).toString('base64')

    callback = url.parse(request.url, true).query['callback']
    # should we return JSON or JSONP (callback defined)?
    if callback?
      response.writeHead 200, { 'Content-Type': 'application/javascript' }
      return response.end "#{callback}(#{JSON.stringify(resp_obj)})", 'utf8'
    else
      response.writeHead 200, { 'Content-Type': 'application/json' }
      return response.end "#{JSON.stringify(resp_obj)}", 'utf8'

router.post '/*', (request, response) ->
  # We only support application/json
  if request.headers['content-type'] isnt 'application/json'
    response.writeHead 415, { 'Content-Type': 'application/json' }
    return response.end "#{JSON.stringify(error: 'Only content-type application/json supported')}", 'utf8'

  # the the FS path
  fs_path = request.fs_path

  # Handle 'This PC'
  if target_app.platform is target_app.supported_platforms.WINDOWS_PC and fs_path is ''
    response.writeHead 403, { 'Content-Type': 'application/json' }
    return response.end "#{JSON.stringify(error: 'Cannot create a file or directory in \'This PC\'')}", 'utf8'

  # get stats and check if file exists
  try
    stats = fs.statSync fs_path
  catch err
    if err.code is 'ENOENT'
      response.writeHead 404, { 'Content-Type': 'application/json' }
      return response.end "#{JSON.stringify(error: 'No such file or directory')}", 'utf8'
    else
      response.writeHead 500, { 'Content-Type': 'application/json' }
      return response.end "#{JSON.stringify(error: 'Unable to open ' + path.basename fs_path)}", 'utf8'

  # return an error if fs_path does not point to a directory
  if !stats.isDirectory()
    response.writeHead 400, { 'Content-Type': 'application/json' }
    return response.end "#{JSON.stringify(error: path.basename(fs_path) + ' is not a directory')}", 'utf8'

  # Validate the name
  if not request.body.name?
      response.writeHead 422, { 'Content-Type': 'application/json' }
      return response.end "#{JSON.stringify(error: 'Parameter \'name\' missing')}", 'utf8'

  # And check if the file is not existing yet
  new_fs_path = path.join fs_path, request.body.name
  try
    fs.statSync new_fs_path
    response.writeHead 409, { 'Content-Type': 'application/json' }
    return response.end "#{JSON.stringify(error: request.body.name + ' already exists')}", 'utf8'
  catch err
    # ENOENT --> file does not exist yet; error is not ENOENT --> something happended --> error
    if err.code isnt 'ENOENT'
      response.writeHead 500, { 'Content-Type': 'application/json' }
      return response.end "#{JSON.stringify(error: 'Unable to open ' + path.basename fs_path)}", 'utf8'

  # Validate the type
  if not request.body.type?
    response.writeHead 422, { 'Content-Type': 'application/json' }
    return response.end "#{JSON.stringify(error: 'Parameter \'type\' missing')}", 'utf8'
  if request.body.type not in ['file', 'directory']
    response.writeHead 422, { 'Content-Type': 'application/json' }
    return response.end "#{JSON.stringify(error: 'Invalid value for parameter \'type\'')}", 'utf8'

  if request.body.type is 'directory'
    fs.mkdirSync new_fs_path
    response.writeHead 201, { 'Location': "#{fs_app.path_2_uri(new_fs_path)}" }
    return response.end()

  else # request.body.type is 'file'
    encoding = if request.body.encoding? then request.body.encoding else 'ascii'
    content = if request.body.content? then request.body.content else ''
    fs.writeFileSync new_fs_path, new Buffer(content, 'base64').toString(encoding), encoding=encoding
    # Note: 201 is also returned if the file did exist
    response.writeHead 201, { 'Location': "#{fs_app.path_2_uri(new_fs_path)}" }
    return response.end()

router.put '/*', (request, response) ->
  # We only support application/json
  if request.headers['content-type'] isnt 'application/json'
    response.writeHead 415, { 'Content-Type': 'application/json' }
    return response.end "#{JSON.stringify(error: 'Only content-type application/json supported')}", 'utf8'

  # the the FS path
  fs_path = request.fs_path

  # Handle 'This PC'
  if target_app.platform is target_app.supported_platforms.WINDOWS_PC and fs_path is ''
    response.writeHead 403, { 'Content-Type': 'application/json' }
    return response.end "#{JSON.stringify(error: 'Cannot modify \'This PC\'')}", 'utf8'

  # get stats and check if file exists
  try
    stats = fs.statSync fs_path
  catch err
    if err.code is 'ENOENT'
      response.writeHead 404, { 'Content-Type': 'application/json' }
      return response.end "#{JSON.stringify(error: 'No such file or directory')}", 'utf8'
    else
      response.writeHead 500, { 'Content-Type': 'application/json' }
      return response.end "#{JSON.stringify(error: 'Unable to open ' + path.basename fs_path)}", 'utf8'

  # return an error if fs_path does not point to a directory
  if stats.isDirectory()
    response.writeHead 400, { 'Content-Type': 'application/json' }
    return response.end "#{JSON.stringify(error: path.basename(fs_path) + ' is a directory')}", 'utf8'

  encoding = if request.body.encoding? then request.body.encoding else 'ascii'
  content = if request.body.content? then request.body.content else ''
  fs.writeFileSync fs_path, new Buffer(content, 'base64').toString(encoding), encoding=encoding
  response.writeHead 204
  return response.end()

router.delete '/*', (request, response) ->
  # the the FS path
  fs_path = request.fs_path

  # Handle 'This PC'
  if target_app.platform is target_app.supported_platforms.WINDOWS_PC and fs_path is ''
    response.writeHead 403, { 'Content-Type': 'application/json' }
    return response.end "#{JSON.stringify(error: 'Cannot delete \'This PC\'')}", 'utf8'

  # delete file
  try
    fs.unlinkSync fs_path
    response.writeHead 204
    return response.end()
  catch err
    if err.code is 'ENOENT'
      response.writeHead 404, { 'Content-Type': 'application/json' }
      return response.end "#{JSON.stringify(error: 'No such file or directory')}", 'utf8'
    else  # the file exists but we cannot delete it...
      response.writeHead 403, { 'Content-Type': 'application/json' }
      return response.end "#{JSON.stringify(error: 'Unable to delete ' + path.basename fs_path)}", 'utf8'

# return unsupported method for anything not handlet yet
router.use '/', (request, response, next) ->
  err_resp =
    error: 'Unable to handle request'
    reason: request.method + ' not allowed'

  response.writeHead 405, { 'Content-Type': 'application/json' }
  return response.end "#{JSON.stringify(err_resp)}", 'utf8'

# export the app object
module.exports = fs_app
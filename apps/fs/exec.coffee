url = require 'url'
fs = require 'fs'
path = require 'path'
mime = require 'mime'
app_manifest = require './manifest.json'
app_catalog = require '../../shared/scripts/app-catalog.coffee'
target_app = app_catalog.catalog['Target information'].get_instance()

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

module.exports =
  init: (app) ->
    # add the home folder
    app.web_api.fs['home_uri'] = @get_home_uri()

  exec: ->

  get_home_uri: () ->
    home_path = process.env[ if target_app.platform is target_app.supported_platforms.WINDOWS_PC then 'USERPROFILE' else 'HOME']
    return "#{app_manifest.web_api.fs.uri}#{home_path.replace(new RegExp('\\' + path.sep, 'g'), '/')}"

  handle_fs: (request, response, next) ->
    # the the FS path
    fs_path = url.parse(request.url, true).pathname
    fs_path = fs_path.replace /(\/)/g, path.sep
    if target_app.platform is target_app.supported_platforms.WINDOWS_PC
      fs_path = fs_path.substr 1
      if fs_path.slice(-1) is ':'
        fs_path = fs_path + path.sep

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
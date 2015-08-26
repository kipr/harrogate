FS = require 'fs'
Path = require 'path'
Q = require 'q'
spawn = require('child_process').spawn

AppCatalog = require_harrogate_module '/shared/scripts/app-catalog.coffee'
ServerError = require_harrogate_module '/shared/scripts/server-error.coffee'

TargetApp = AppCatalog.catalog['Target information'].get_instance()

AppManifest = require './manifest.json'

class HostFileSystem
  constructor: ->
    # get the drive letters
    @win_drive_letters = []
    if TargetApp.platform is TargetApp.supported_platforms.WINDOWS_PC
      list = spawn 'cmd'
      list.stdout.on 'data', (data) =>
        data_str = '' + data
        matches = data_str.match /^(.:)(?!\S)/gm
        if matches? then @win_drive_letters.push match for match in matches
        return
      list.stderr.on 'data', (data) ->
        console.log 'stderr: ' + data
        return
      list.on 'exit', (code) ->
        return
      list.stdin.write 'wmic logicaldisk get name\n'
      list.stdin.end()

  uri_2_path: (uri) ->
    # decode uri
    uri = decodeURI uri

    # uri = <AppManifest.web_api.fs.uri>/<path>
    path = uri.substr AppManifest.web_api.fs.uri.length

    # '/' --> os dependent path separator
    path = path.replace /(\/)/g, Path.sep

    # For Windows '\C:' --> C:\
    if TargetApp.platform is TargetApp.supported_platforms.WINDOWS_PC
      path = path.substr 1
      if path.slice(-1) is ':'
        path = path + Path.sep

    return path

  path_2_uri: (path) ->
    # os dependent path separator --> '/'
    uri = path.replace new RegExp('\\' + Path.sep, 'g'), '/'

    # <path>/ --> <path>
    if uri.slice(-1) is '/'
      uri = uri.slice(0, -1)

    # For Windows 'C:' --> \C:
    if TargetApp.platform is TargetApp.supported_platforms.WINDOWS_PC
      uri = '/' + uri

    # <path> --> <AppManifest.web_api.fs.uri>/<path>
    uri = "#{AppManifest.web_api.fs.uri}" + uri

    return encodeURI uri

  open: (param) =>
    # path overwrites uri
    return @open_from_path param.path if param.path?
    return @open_from_uri param.uri if param.uri?

    # fallback: param = path
    return @open_from_path param

  open_from_uri: (uri) =>
    return @open_from_path @uri_2_path(uri)

  open_from_path: (path) =>
    # we have to require Directory and File here to avoid circular dependency issues
    Directory = require './directory.coffee'
    File = require './file.coffee'

    # empty path is OK for windows; and it's a directory
    if TargetApp.platform is TargetApp.supported_platforms.WINDOWS_PC and path is ''
      return Q(Directory.create_from_path(path))

    else # it looks like a regular path; does it exists?
      deferred = Q.defer()
      FS.stat path, (err, stats) ->
        if err?
          deferred.reject new ServerError 404, path + ': No such file or directory'
          return

        # it exists; is it a file or directory?
        if stats.isDirectory()
          deferred.resolve Directory.create_from_path(path)
          return
        else
          deferred.resolve File.create_from_path(path)
          return

      # return the promise that we will return a fs resource once fs.stat returns
      return deferred.promise

module.exports = new HostFileSystem
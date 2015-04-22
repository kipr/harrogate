FS = require 'fs'
Mime = require 'mime'
Path = require 'path'
Q = require 'q'

AppCatalog = require '../../shared/scripts/app-catalog.coffee'
ServerError = require '../../shared/scripts/server-error.coffee'
TargetApp = AppCatalog.catalog['Target information'].get_instance()

AppManifest = require './manifest.json'

# Helper functions
####################################################################################################
uri_2_path = (uri) ->
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

path_2_uri = (path) ->
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

  return uri

# get the drive letters
win_drive_letters = []
if TargetApp.platform is TargetApp.supported_platforms.WINDOWS_PC
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

# class FsDirectoryResource
####################################################################################################
class FsDirectoryResource
  constructor: (@uri) ->
    @path = uri_2_path @uri

    if TargetApp.platform is TargetApp.supported_platforms.WINDOWS_PC and @path is ''
      @name = 'This PC'
    else
      @name = if (@path.slice(-2) is (':' + Path.sep)) then @path else Path.basename @path

  @create_from_path: (path) ->
    return new @ path_2_uri path

  get_parent: () =>
    # 'this PC' special case
    if @path is '' # 'this PC' resource has no parent
      return Q(undefined)

    # Windows drive letter special case
    if TargetApp.platform is TargetApp.supported_platforms.WINDOWS_PC and (@path.slice(-2) is (':' + Path.sep))
      return fs_resource_factory.create_from_path ''

    parent_path = Path.dirname @path
    if parent_path is @path # this resource has no parent
      return Q(undefined)
    else # there exists a parent
      return fs_resource_factory.create_from_path parent_path

  get_children: () =>
    if TargetApp.platform is TargetApp.supported_platforms.WINDOWS_PC and @path is ''
      # Children = windows drive letters
      return Q(drive_letter + Path.sep for drive_letter in win_drive_letters)
    else
      # Children = @path/*
      return Q.nfcall FS.readdir, @path

  is_valid: () =>
    # 'this PC' is always valid
    if TargetApp.platform is TargetApp.supported_platforms.WINDOWS_PC and @path is ''
      return Q(true)

    # else check the stats
    return Q.nfcall FS.stat, @path
    .then ((stats) ->
      # it exists; is it a directory?
      if stats.isDirectory()
        return Q(true)
      else
        return Q(false)
    ), (err) ->
      return Q(false)

  get_representation: (verbose = true) =>
    representation =
      name: @name
      type: 'Directory'
      links:
        self:
          href: @uri

    # add path (not for 'This PC')
    if not (TargetApp.platform is TargetApp.supported_platforms.WINDOWS_PC and @path is '')
      representation.path = @path

    # >>> Async part. Return a promise and continue
    # check if the resource is valid
    return @is_valid()
    .then (valid) =>
      # throw an error if it's not valid
      if not valid
        throw new ServerError 400, @path + ' is not a directory'

      if not verbose
        # we are done if we don't have to include parent / children
        return Q(representation)

      else
        # get the parent resource
        return @get_parent()
        .then (parent_resource) =>
          if parent_resource?
            # resource has a parent, add it
            return parent_resource.get_representation false
          else
            # there is no parent
            return Q(undefined)

        .then (parent_representation) =>
          # Add the parent representation
          representation.parent = parent_representation

          # get the children
          return @get_children()

        .then (children) =>
          # get a list of all children; allSettled bc not all children (e.g. Floppy) might be accessible
          return Q.allSettled children.map( (child_name) =>
            if @path.slice(-1) is Path.sep # fix for windows drive letters
              path = @path
            else
              path = @path + Path.sep
            return fs_resource_factory.create_from_path(path + child_name))

        .then (child_resource_promises) =>
          # ignore rejected promises; get the compact representation of all resources
          return Q.allSettled (promise.value for promise in child_resource_promises when promise.state is 'fulfilled').map((child_resource) =>
            return child_resource.get_representation false )

        .then (child_representation_promises) =>
          # add the children
          representation.children = (promise.value for promise in child_representation_promises when promise.state is 'fulfilled')

          # finally done
          return Q(representation)

  create_file: (name, content, encoding) =>
    # Handle 'This PC'
    if TargetApp.platform is TargetApp.supported_platforms.WINDOWS_PC and @path is ''
      throw new ServerError 403, 'Cannot create a file in \'This PC\''

    # compose the child path
    child_path = Path.join @path, name

    # >>> Async part. Return a promise and continue
    # check if the resource is valid
    return @is_valid()
    .then (valid) =>
      # throw an error if it's not valid
      if not valid
        throw new ServerError 400, @path + ' is not a directory'

      # get the stats (we can as 'this pc' is already handled)
      return Q.nfcall FS.stat, child_path
    .then ((stats) =>
      # file does exist --> error
      throw new ServerError 409, name + ' already exists'
    ), (err) =>
       # error is not ENOENT --> something happended --> error
      if err.code isnt 'ENOENT'
        throw new ServerError 500, 'Unable to open ' + child_path

      # get the file resource
      file_resource = FsFileResource.create_from_path child_path

      # create the file
      return file_resource.write content, encoding
      .then () =>

        # return the file resource once the write has finished
        return file_resource

  create_subdirectory: (name) =>
    # Handle 'This PC'
    if TargetApp.platform is TargetApp.supported_platforms.WINDOWS_PC and @path is ''
      throw new ServerError 403, 'Cannot create a file or directory in \'This PC\''

    # compose the child path
    child_path = Path.join @path, name

    # >>> Async part. Return a promise and continue
    # check if the resource is valid
    return @is_valid()
    .then (valid) =>
      # throw an error if it's not valid
      if not valid
        throw new ServerError 400, @path + ' is not a directory'

      # get the stats (we can as 'this pc' is already handled)
      return Q.nfcall FS.stat, child_path
    .then ((stats) =>
      # file does exist --> error
      throw new ServerError 409, name + ' already exists'
    ), (err) =>
       # error is not ENOENT --> something happended --> error
      if err.code isnt 'ENOENT'
        throw new ServerError 500, 'Unable to open ' + child_path

      # create the directory
      return Q.nfcall FS.mkdir, child_path
      .then () =>
        # directory created, return resource
        return fs_resource_factory.create_from_path child_path

  remove: () =>
    return Q.nfcall FS.rmdir, @path

# class FsFileResource
####################################################################################################
class FsFileResource
  constructor: (@uri) ->
    @path = uri_2_path @uri
    @name = Path.basename @path

  @create_from_path: (path) ->
    return new @ path_2_uri path

  get_parent: () =>
    # 'this PC' special case
    if @path is '' # 'this PC' resource has no parent
      return Q(undefined)

    # Windows drive letter special case
    if TargetApp.platform is TargetApp.supported_platforms.WINDOWS_PC and (@path.slice(-2) is (':' + Path.sep))
      return fs_resource_factory.create_from_path ''

    parent_path = Path.dirname @path
    if parent_path is @path # this resource has no parent
      return Q(undefined)
    else # there exists a parent
      return fs_resource_factory.create_from_path parent_path

  is_valid: () =>
    # 'this PC' is always valid
    if TargetApp.platform is TargetApp.supported_platforms.WINDOWS_PC and @path is ''
      return Q(true)

    # else check the stats
    return Q.nfcall FS.stat, @path
    .then ((stats) ->
      # it exists; is it a directory?
      if stats.isFile()
        return Q(true)
      else
        return Q(false)
    ), (err) ->
      return Q(false)

  get_representation: (verbose = true) =>
    representation =
      name: @name
      path: @path
      type: Mime.lookup @path
      links:
        self:
          href: @uri

    # >>> Async part. Return a promise and continue
    # check if the resource is valid
    return @is_valid()
    .then (valid) =>
      # throw an error if it's not valid
      if not valid
        throw new ServerError 400, @path + ' is not a file'

      if not verbose
        # we are done if we don't have to include parent / content
        return Q(representation)

      else
        # get the parent resource
        return @get_parent()
        .then (parent_resource) =>
          if parent_resource?
            # resource has a parent, add it
            return parent_resource.get_representation false
          else
            # there is no parent
            return Q(undefined)

        .then (parent_representation) =>
          # Add the parent representation
          representation.parent = parent_representation

          # get the content
          return Q.nfcall FS.readFile, @path

        .then (content) =>
          representation.content = content.toString('base64')

          # finally done
          return Q(representation)

  write: (content, encoding) =>
    encoding ?= 'ascii'
    content ?= ''

    return Q.nfcall FS.writeFile, @path, new Buffer(content, 'base64').toString(encoding), encoding=encoding

  remove: () =>
    return Q.nfcall FS.unlink, @path

# class FsResourceFactory
####################################################################################################
class FsResourceFactory
  FsFileResource: FsFileResource
  FsDirectoryResource: FsDirectoryResource

  create_from_uri: (uri) =>
    return @create_from_path uri_2_path(uri)

  create_from_path: (path) =>
    # empty path is OK for windows; and it's a folder
    if TargetApp.platform is TargetApp.supported_platforms.WINDOWS_PC and path is ''
      return Q(FsDirectoryResource.create_from_path(path))

    else # it looks like a regular path; does it exists?
      deferred = Q.defer()
      FS.stat path, (err, stats) ->
        if err?
          deferred.reject new ServerError 404, path + ': No such file or directory'
          return

        # it exists; is it a file or directory?
        if stats.isDirectory()
          deferred.resolve FsDirectoryResource.create_from_path(path)
          return
        else
          deferred.resolve FsFileResource.create_from_path(path)
          return

      # return the promise that we will return a fs resource once fs.stat returns
      return deferred.promise

module.exports = fs_resource_factory = new FsResourceFactory
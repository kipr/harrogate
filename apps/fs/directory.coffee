FS = require 'fs'
Path = require 'path'
Rmdir = require 'rimraf'
Q = require 'q'

AppCatalog = require_harrogate_module '/shared/scripts/app-catalog.coffee'
HostFileSystem = require './host-fs.coffee'
ServerError = require_harrogate_module '/shared/scripts/server-error.coffee'

TargetApp = AppCatalog.catalog['Target information'].get_instance()

class Directory
  constructor: (@uri) ->
    @path = HostFileSystem.uri_2_path @uri

    if TargetApp.platform is TargetApp.supported_platforms.WINDOWS_PC and @path is ''
      @name = 'This PC'
    else
      @name = if (@path.slice(-2) is (':' + Path.sep)) then @path else Path.basename @path

  @create_from_path: (path) ->
    return new @ HostFileSystem.path_2_uri path

  get_parent: () =>
    # >>> Async part. Return a promise and continue
    # check if the resource is valid
    return @is_valid()
    .then (valid) =>
      # throw an error if it's not valid
      if not valid
        throw new ServerError 400, @path + ' is not a directory'

      # 'this PC' special case
      if @path is '' # 'this PC' resource has no parent
        return Q(undefined)

      # Windows drive letter special case
      if TargetApp.platform is TargetApp.supported_platforms.WINDOWS_PC and (@path.slice(-2) is (':' + Path.sep))
        return Directory.create_from_path ''

      parent_path = Path.dirname @path
      if parent_path is @path # this resource has no parent
        return Q(undefined)
      else # there exists a parent
        return Directory.create_from_path parent_path

  get_child: (name) =>
    return @get_children()
    .then (children) =>
      child = (child for child in children when child.name is name)[0]
      if not child?
        throw new ServerError 404, name + ' is not a child of ' + @path

      return child

  get_children: () =>
    if TargetApp.platform is TargetApp.supported_platforms.WINDOWS_PC and @path is ''
      # Children = windows drive letters
      promise = Q(drive_letter + Path.sep for drive_letter in HostFileSystem.win_drive_letters)
    else
      # Children = @path/*
      promise = Q.nfcall FS.readdir, @path

    promise.then (children) =>
      # get a list of all children; allSettled bc not all children (e.g. Floppy) might be accessible
      return Q.allSettled children.map( (child_name) =>
        if @path.slice(-1) is Path.sep or @path is '' # fix for windows drive letters and 'this PC'
          path = @path
        else
          path = @path + Path.sep
        return HostFileSystem.open(path + child_name))

    .then (child_resource_promises) =>
      # ignore rejected promises; return fulfilled as array
      return (promise.value for promise in child_resource_promises when promise.state is 'fulfilled')

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

        .then (child_resources) =>
          # get the compact representation of all resources
          return Q.allSettled child_resources.map((child_resource) =>
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
      # we have to require File here to avoid circular dependency issues
      File = require './file.coffee'
      file_resource = File.create_from_path child_path

      # create the file
      return file_resource.write content, encoding
      .then () =>

        # return the file resource once the write has finished
        return file_resource

  create: =>
    # Handle 'This PC'
    if TargetApp.platform is TargetApp.supported_platforms.WINDOWS_PC and @path is ''
      throw new ServerError 403, 'Cannot create \'This PC\''

    # >>> Async part. Return a promise and continue
    # create the directory
    return Q.nfcall FS.mkdir, @path
    .then () =>
      # directory created, return resource
      return this

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
        return Directory.create_from_path child_path

  remove: () =>
    deferred = Q.defer()
    Rmdir @path, (error) =>
      if error
        deferred.reject new ServerError(403, 'Unable to delete ' + @path)
      else
        deferred.resolve()

    return deferred.promise

module.exports = Directory
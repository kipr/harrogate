FS = require 'fs'
Path = require 'path'
Q = require 'q'
Mime = require 'mime'

AppCatalog = require '../../shared/scripts/app-catalog.coffee'
HostFileSystem = require './host-fs.coffee'
ServerError = require '../../shared/scripts/server-error.coffee'

TargetApp = AppCatalog.catalog['Target information'].get_instance()

class File
  constructor: (@uri) ->
    @path = HostFileSystem.uri_2_path @uri
    @name = Path.basename @path

  @create_from_path: (path) ->
    return new @ HostFileSystem.path_2_uri path

  get_parent: () =>
    # >>> Async part. Return a promise and continue
    # check if the resource is valid
    return @is_valid()
    .then (valid) =>
      # throw an error if it's not valid
      if not valid
        throw new ServerError 400, @path + ' is not a file'

      # if our is_valid works, parent_path should be always defined and points to a directory
      # we have to require Directory here to avoid circular dependency issues
      Directory = require './directory.coffee'
      return Directory.create_from_path Path.dirname @path

  is_valid: () =>
    # 'this PC' is not a valid file
    if TargetApp.platform is TargetApp.supported_platforms.WINDOWS_PC and @path is ''
      return Q(false)

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

    return Q.nfcall FS.writeFile, @path, content, encoding=encoding

  remove: () =>
    return Q.nfcall FS.unlink, @path

module.exports = File
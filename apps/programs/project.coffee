FS = require 'fs'
Path = require 'path'
Q = require 'q'
_ = require 'lodash'

AppCatalog = require '../../shared/scripts/app-catalog.coffee'

FsApp = AppCatalog.catalog['Host Filesystem'].get_instance()
Directory = require AppCatalog.catalog['Host Filesystem'].path + '/directory.coffee'

AppManifest = require './manifest.json'

get_file_representations = (directory) ->
  return directory.is_valid()
  .then (valid) =>
    if not valid
      return Q undefined

    else
      directory.get_children()
      .then (children) =>
        # get the compact representation of all resources
        return Q.allSettled children.map((child) =>
          return child.get_representation false )

      .then (child_representation_promises) =>
        # add the children
        return (promise.value for promise in child_representation_promises when promise.state is 'fulfilled')

class Project
  constructor: (
    @name
    @project_file

    # the directories doesn't have to exist yet but should point to a valid location
    @include_directory
    @src_directory
    @data_directory
    @bin_directory
    @lib_directory
  ) ->
    @uri = AppManifest.web_api.projects.uri + '/' + encodeURIComponent @name

  is_valid: =>
    return @project_file.is_valid()

  get_representation: (verbose = true) =>
    representation =
      name: @name
      links:
        self:
          href: @uri

    if verbose
      _.merge(representation, 
        links:
          project_file:
            href: @project_file.uri
          include_directory:
            href: @include_directory.uri
          src_directory:
            href: @src_directory.uri
          data_directory:
            href: @data_directory.uri
          bin_directory:
            href: @bin_directory.uri
          lib_directory:
            href: @lib_directory.uri
      )

    # >>> Async part. Return a promise and continue
    # get the .project.json file content
    return Q.nfcall FS.readFile, @project_file.path
    .then (content) =>
      project_parameters = JSON.parse content

      if not verbose # just add the project language and return
        representation.parameters = 
          language: project_parameters.language
        return representation

      else
        # add the all parameters
        representation.parameters = project_parameters

        # add all the project files
        return Q.all([
          get_file_representations @include_directory
          get_file_representations @src_directory
          get_file_representations @data_directory
          get_file_representations @bin_directory
          get_file_representations @lib_directory
        ])
        .then (values) =>
          if values[0]?
            representation.include_files = values[0]
          if values[1]?
            representation.source_files = values[1]
          if values[2]?
            representation.data_files = values[2]
          if values[3]?
            representation.binary_files = values[3]
          if values[4]?
            representation.library_files = values[4]

          # finally done
          return representation

module.exports = Project
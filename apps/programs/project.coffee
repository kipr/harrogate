FS = require 'fs'
Path = require 'path'
Q = require 'q'

AppCatalog = require '../../shared/scripts/app-catalog.coffee'

FsApp = AppCatalog.catalog['Host Filesystem'].get_instance()
Directory = require AppCatalog.catalog['Host Filesystem'].path + '/directory.coffee'

AppManifest = require './manifest.json'

class Project
  constructor: (@project_directory) ->
    @name = @project_directory.name
    @uri = AppManifest.web_api.projects.uri + '/' + encodeURIComponent @name

  is_valid: =>
    return @project_directory.is_valid()

  get_representation: (verbose = true) =>
    representation =
      name: @name
      links:
        self:
          href: @uri
        fs_resource:
          href: @project_directory.uri

    # >>> Async part. Return a promise and continue
    # get the .project.json file content
    return Q.nfcall FS.readFile, Path.join @project_directory.path, '.project.json'
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
        return @project_directory.get_children()

        .then (children) =>
          # get the compact representation of all resources
          return Q.allSettled children.map((child) =>
            return child.get_representation false )

        .then (child_representation_promises) =>
          # add the children
          representation.files = (promise.value for promise in child_representation_promises when promise.state is 'fulfilled')

            # finally done
          return representation

module.exports = Project
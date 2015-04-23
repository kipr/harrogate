FS = require 'fs'
Path = require 'path'
Q = require 'q'
AppCatalog = require '../../shared/scripts/app-catalog.coffee'
TargetApp = AppCatalog.catalog['Target information'].get_instance()
FsApp = AppCatalog.catalog['Host Filesystem'].get_instance()
FsResourceFactory = FsApp.FsResourceFactory
FsFileResource = FsResourceFactory.FsFileResource
FsDirectoryResource = FsResourceFactory.FsDirectoryResource

# class ProjectResource
####################################################################################################
class ProjectResource
  constructor: (@uri, @base_fs_resource) ->
    @name = @base_fs_resource.name

  is_valid: =>
    return @base_fs_resource.is_valid()

  get_representation: (verbose = true) =>
    representation =
      name: @name
      links:
        self:
          href: @uri
        fs_resource:
          href: @base_fs_resource.uri

    # >>> Async part. Return a promise and continue
    # get the .project.json file content
    return Q.nfcall FS.readFile, Path.join @base_fs_resource.path, '.project.json'
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
        return @base_fs_resource.get_children()

        .then (child_resources) =>
          # get the compact representation of all resources
          return Q.allSettled child_resources.map((child_resource) =>
            return child_resource.get_representation false )

        .then (child_representation_promises) =>
          # add the children
          representation.files = (promise.value for promise in child_representation_promises when promise.state is 'fulfilled')

            # finally done
          return representation

# class WsResource
####################################################################################################
class WsResource
  constructor: (@uri, @base_fs_resource) ->

  is_valid: =>
    return @base_fs_resource.is_valid()

  get_projects: =>
    # a project is a folder (for now :P)
    @base_fs_resource.get_children()
    .then (child_resources) =>

      #create the project resources (exclude non-folders)
      project_resources = (child_resource for child_resource in child_resources when child_resource instanceof FsDirectoryResource ).map (child_resource) =>
        return new ProjectResource @uri + '/' + encodeURIComponent(child_resource.name), child_resource

  get_representation: =>
    representation =
      links:
        self:
          href: @uri
        fs_resource:
          href: @base_fs_resource.uri

    # get the projects
    return @get_projects()
    .then (project_resources) =>

      # get the representation of all project resources
      return Q.allSettled project_resources.map((project_resource) =>
        return project_resource.get_representation false )

    .then (project_representation_promises) =>
      # add the projects (just the valid ones)
      console.log project_representation_promises
      representation.projects = (promise.value for promise in project_representation_promises when promise.state is 'fulfilled')

      return representation

  create_project: (name, language) =>
    # create a subdirectory for the project
    return @base_fs_resource.create_subdirectory name
    .then (project_base_directory_resource) =>

      # create the project file
      content = JSON.stringify language: language
      return project_base_directory_resource.create_file '.project.json', content, 'ascii'
      .then (project_file_resource) =>
        return new ProjectResource @uri + '/' + encodeURIComponent(name), project_base_directory_resource

module.exports = 
  WsResource: WsResource

  create: (uri, base_fs_resource) ->
    return new WsResource uri, base_fs_resource
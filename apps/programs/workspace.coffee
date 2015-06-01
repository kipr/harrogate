Q = require 'q'

AppCatalog = require '../../shared/scripts/app-catalog.coffee'
Project = require './project.coffee'

FsApp = AppCatalog.catalog['Host Filesystem'].get_instance()
Directory = require AppCatalog.catalog['Host Filesystem'].path + '/directory.coffee'

AppManifest = require './manifest.json'

class Workspace
  constructor: (@ws_directory) ->
    @uri = AppManifest.web_api.projects.uri

  is_valid: =>
    return @ws_directory.is_valid()

  get_projects: =>
    # a project is a folder (for now :P)
    @ws_directory.get_children()
    .then (children) =>
      #create the project resources (exclude non-folders)
      project_resources = (child for child in children when child instanceof Directory).map (child) =>
        return new Project child

  get_representation: =>
    representation =
      links:
        self:
          href: @uri
        fs_resource:
          href: @ws_directory.uri

    # get the projects
    return @get_projects()
    .then (project_resources) =>

      # get the representation of all project resources
      return Q.allSettled project_resources.map((project_resource) =>
        return project_resource.get_representation false )

    .then (project_representation_promises) =>
      # add the projects (just the valid ones)
      representation.projects = (promise.value for promise in project_representation_promises when promise.state is 'fulfilled')

      return representation

  create_project: (name, language) =>
    # create a subdirectory for the project
    return @ws_directory.create_subdirectory name
    .then (project_directory) =>

      # create the project file
      content = JSON.stringify language: language
      return project_directory.create_file '.project.json', content, 'ascii'
      .then (project_file) =>
        return new Project project_directory


module.exports = Workspace
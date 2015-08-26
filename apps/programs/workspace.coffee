Path = require 'path'
Q = require 'q'

AppCatalog = require_harrogate_module '/shared/scripts/app-catalog.coffee'
Project = require './project.coffee'

FsApp = AppCatalog.catalog['Host Filesystem'].get_instance()
Directory = require AppCatalog.catalog['Host Filesystem'].path + '/directory.coffee'
File = require AppCatalog.catalog['Host Filesystem'].path + '/file.coffee'

AppManifest = require './manifest.json'

class Workspace
  constructor: (@ws_directory) ->
    @uri = AppManifest.web_api.projects.uri

    @include_directory = Directory.create_from_path Path.join(@ws_directory.path, 'include')
    @src_directory = Directory.create_from_path Path.join(@ws_directory.path, 'src')
    @data_directory = Directory.create_from_path Path.join(@ws_directory.path, 'data')
    @bin_directory = Directory.create_from_path Path.join(@ws_directory.path, 'bin')
    @lib_directory = Directory.create_from_path Path.join(@ws_directory.path, 'lib')

  is_valid: =>
    return Q.all([
      @ws_directory.is_valid()
      @include_directory.is_valid()
      @src_directory.is_valid()
      @data_directory.is_valid()
      @bin_directory.is_valid()
      @lib_directory.is_valid()
    ])
    .then (values) ->
      return values.reduce (previousValue, currentValue) ->
        return previousValue and currentValue

  get_projects: =>
    # a project has at least a project file *.project.json located in the workspace root
    @ws_directory.get_children()
    .then (children) =>
      #create the project resources (exclude non-folders)
      project_resources = (child for child in children when child instanceof File).map (child) =>
        project_name = child.name.slice 0, -13
        return new Project(
          project_name
          child
          Directory.create_from_path Path.join @include_directory.path, project_name
          Directory.create_from_path Path.join @src_directory.path, project_name
          Directory.create_from_path Path.join @data_directory.path, project_name
          Directory.create_from_path Path.join @bin_directory.path, project_name
          Directory.create_from_path Path.join @lib_directory.path, project_name
        )

  get_representation: =>
    representation =
      links:
        self:
          href: @uri
        ws_directory:
          href: @ws_directory.uri
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

  init: =>

  create_project: (name, language) =>
    # create the project file
    content = JSON.stringify language: language
    return @ws_directory.create_file name + '.project.json', content, 'ascii'
    .then (project_file) =>
      return new Project(
        name
        project_file
        Directory.create_from_path Path.join @include_directory.path, name
        Directory.create_from_path Path.join @src_directory.path, name
        Directory.create_from_path Path.join @data_directory.path, name
        Directory.create_from_path Path.join @bin_directory.path, name
        Directory.create_from_path Path.join @lib_directory.path, name
      )

module.exports = Workspace
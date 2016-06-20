Fs = require 'fs'
Path = require 'path'
Q = require 'q'
Tar = require 'tar-stream'

AppCatalog = require_harrogate_module '/shared/scripts/app-catalog.coffee'
Project = require './project.coffee'
ServerError = require_harrogate_module '/shared/scripts/server-error.coffee'

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

  get_project: (name) =>
    return @get_projects()
    .then (projects) =>
      project = (project for project in projects when project.name is name)[0]
      if not project?
        throw new ServerError 404, 'This workspace does not contain a project named ' +name

      return project

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

  import_from_archive: (pack) =>
    return Q.Promise (resolve, reject, notify) =>

      extract = Tar.extract()
      extract.on 'entry', (header, stream, callback) =>
        [ project_name, type, file_name ] = header.name.split '/'

        # skip this file if any of project_name, type, file_name is not set
        if not project_name? or not type? or not file_name?
          callback()
          return

        type_root_directory_resource = switch type
          when 'include' then @include_directory
          when 'src' then @src_directory
          when 'data' then @data_directory

        if not type_root_directory_resource?
          callback()
          return

        return type_root_directory_resource.is_valid()

        .then (valid) =>
          # create <ws>/<type> if it is not existing
          return if not valid then Q.nfcall Fs.mkdir, type_root_directory_resource.path else Q(undefined)

        .then =>
          # get the project resource
          return @get_project project_name
        .then ( (project_resource) =>
          # the project already exist
          return project_resource
         ), (error) =>
          if error?.code? and error.code is 404
            # the project does not exist yet, create it
            return @create_project project_name, 'C'
          else
            # some other error happended, rethrow
            throw error

        # get the directory resource and check if it is valid (= existing)
        .then (project_resource) =>
          directory_resource = switch type
            when 'include' then project_resource.include_directory
            when 'src' then project_resource.src_directory
            when 'data' then project_resource.data_directory

          return [ Q(directory_resource), directory_resource.is_valid() ]

        .spread (directory_resource, valid) =>
          # create <ws>/<type>/<prj> if it is not existing
          return [ Q(directory_resource), if not valid then Q.nfcall Fs.mkdir, directory_resource.path else Q(undefined) ]

        .spread (directory_resource) =>
          # create the file
          fs_write_stream = Fs.createWriteStream Path.join directory_resource.path, file_name

          stream.pipe fs_write_stream
          stream.on 'end', =>
            callback()

        .catch (error) =>
          # an error happened, continue with the next file
          console.log "Unexpected error while importing #{project_name}/#{type}/#{file_name}"
          console.log error
          callback()

        .done()

      extract.on 'error', (error) ->
        reject error

      extract.on 'finish', ->
        resolve()

      pack.pipe extract

  create_project: (name, language, src_file_name) =>
    if not src_file_name?
      src_file_name = 'main.c'

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
    .then (project_resource) =>
      return project_resource.src_directory.create()
      .then =>
        if (language == 'Python')
          content = """
                  #!/usr/bin/python

                  import wallaby

                  def main()
                    print "Hello World"

                  if __name__=="__main__"
                    main()
                  """
        else
          content = """
                  #include <kipr/botball.h>
                          
                  int main()
                  {
                      printf("Hello World\\n");
                      return 0;
                  }
                  """
        return project_resource.src_directory.create_file src_file_name, content, 'ascii'
        .then => 
          return project_resource

module.exports = Workspace

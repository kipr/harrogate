exec = require('child_process').exec
Path = require 'path'

Config = require_harrogate_module 'config.coffee'
ServerError = require_harrogate_module 'shared/scripts/server-error.coffee'

module.exports =

  compile: (project_resource, cb) ->
    project_resource.src_directory.is_valid()

    .then (valid) ->
      if not valid
        throw new ServerError 404, 'Project ' + project_resource.name + ' does not contain any source files'

      return project_resource.src_directory.get_children()

    .then (src_files) ->
      gcc_cmd = "\"#{__dirname}\\mingw.bat\" \"#{Config.ext_deps.min_gw.bin_path}\"
                -I\"#{project_resource.include_directory.path}\"
                -I\"#{Config.ext_deps.include_path}\"
                -g
                -Wall "

      for src in src_files
        if Path.basename(src.path).charAt(0) isnt '.'
          gcc_cmd += '"' + src.path + "\" "

      # add the init helper file
      gcc_cmd += "\"#{Path.resolve(__dirname, '_init_helper.c')}\" "

      #linker options
      gcc_cmd += "-L\"#{Config.ext_deps.lib_path}\"
                  -laurora
                  -o \"#{project_resource.bin_directory.path}\\#{project_resource.name}.exe\" "

      exec gcc_cmd, cb
      return

    .catch (e) ->
      cb e
      return

    .done()
    return

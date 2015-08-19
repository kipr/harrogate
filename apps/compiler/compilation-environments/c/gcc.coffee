exec = require('child_process').exec
Path = require 'path'

module.exports =

  compile: (project_resource, cb) ->
    project_resource.src_directory.is_valid()

    .then (valid) ->
      if not valid
        throw new ServerError 404, 'Project ' + project_resource.name + ' does not contain any source files'

      return project_resource.src_directory.get_children()

    .then (src_files) ->
      gcc_cmd = "gcc -I\"#{project_resource.include_directory.path}\"
                -I\"/opt/KIPR/KISS-web-ide/shared/include\"
                -Wall "

      for src in src_files
        if Path.basename(src.path).charAt(0) isnt '.'
          gcc_cmd += '"' + src.path + "\" "

      gcc_cmd += "-L\"/opt/KIPR/KISS-web-ide/shared/lib\"
                  -laurora
                  -o \"#{project_resource.bin_directory.path}/#{project_resource.name}\" "

      exec gcc_cmd, cb
      return

    .catch (e) ->
      cb e
      return

    .done()
    return

exec = require('child_process').exec
Path = require 'path'

Config = require_harrogate_module 'config.coffee'

module.exports =

  compile: (project_resource, cb) ->
    project_resource.src_directory.is_valid()

    .then (valid) ->
      if not valid
        throw new ServerError 404, 'Python Project ' + project_resource.name + ' does not contain any source files'

      return project_resource.src_directory.get_children()

    .then (src_files) ->
      cp_cmd = "cp "
      pyc_cmd = "python -m py_compile "

      for src in src_files
        if Path.basename(src.path).charAt(0) isnt '.'
          cp_cmd += '"' + src.path + "\" "
          pyc_cmd += "\"#{project_resource.bin_directory.path}/" + src.name + "\" "

      cp_cmd += " \"#{project_resource.bin_directory.path}/\" "

      ln_cmd = "ln -s \"#{project_resource.bin_directory.path}/main.py\" \"#{project_resource.binary.path}\""
      chmod_cmd = "chmod u+x \"#{project_resource.binary.path}\""


      exec cp_cmd
      exec ln_cmd
      exec chmod_cmd
      exec pyc_cmd, cb 
      return

    .catch (e) ->
      cb e
      return

    .done()
    return

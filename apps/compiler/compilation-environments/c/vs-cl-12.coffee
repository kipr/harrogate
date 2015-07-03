Fs = require 'fs'
Path = require 'path'

exec = require('child_process').exec

# assume that the install prefix of the kipr libraries is <harrogate>/../prefix/usr
install_prefix = Path.resolve Path.resolve __dirname, '..', '..', '..', '..', '..' , 'prefix', 'usr'

module.exports =

  compile: (project_resource, cb) ->
    project_resource.src_directory.is_valid()

    .then (valid) ->
      if not valid
        throw new ServerError 404, 'Project ' + project_resource.name + ' does not contain any source files'

      return project_resource.src_directory.get_children()

    .then (src_files) ->

      #compiler options
      cl_cmd = "/I\"#{project_resource.include_directory.path}\"
                /Fe\"#{project_resource.bin_directory.path}\\#{project_resource.name}\" "

      # Add KIPR libraries include paths
      cl_cmd += "/I\"#{Path.resolve(install_prefix, 'include')}\" "

      for src in src_files
        cl_cmd += "\"#{src.path}\" "

      #linker options
      #aurora
      cl_cmd += "/link #{Path.resolve install_prefix, 'lib', 'aurora.lib'}"

      exec 'vs-cl-12.bat ' + cl_cmd, {cwd: Path.resolve(__dirname)}, cb

      return

    .catch (e) ->
      cb e
      return

    .done()
    return
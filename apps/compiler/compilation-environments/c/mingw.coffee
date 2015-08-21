exec = require('child_process').exec
Path = require 'path'

# assume that the install prefix of the kipr libraries is <harrogate>/../prefix/usr
install_prefix = Path.resolve Path.resolve __dirname, '..', '..', '..', '..', '..' , 'prefix', 'usr'

# assume that the MinGW prefix is <harrogate>/../MinGW
mingw_prefix = Path.resolve Path.resolve __dirname, '..', '..', '..', '..', '..' , 'MinGW', 'bin'

module.exports =

  compile: (project_resource, cb) ->
    project_resource.src_directory.is_valid()

    .then (valid) ->
      if not valid
        throw new ServerError 404, 'Project ' + project_resource.name + ' does not contain any source files'

      return project_resource.src_directory.get_children()

    .then (src_files) ->
      gcc_cmd = "\"#{__dirname}\\mingw.bat\" -I\"#{project_resource.include_directory.path}\"
                -I\"/opt/KIPR/KISS-web-ide/shared/include\"
                -Wall "

      # Add KIPR libraries include paths
      gcc_cmd += "-I\"#{Path.resolve(install_prefix, 'include')}\" "

      for src in src_files
        if Path.basename(src.path).charAt(0) isnt '.'
          gcc_cmd += '"' + src.path + "\" "

      # add the init helper file
      gcc_cmd += "\"#{Path.resolve(__dirname, '_init_helper.c')}\" "

      #linker options
      gcc_cmd += "-L\"#{Path.resolve(install_prefix, 'lib')}\"
                  -laurora
                  -o \"#{project_resource.bin_directory.path}\\#{project_resource.name}.exe\" "
				  
      exec gcc_cmd, cb
      return

    .catch (e) ->
      cb e
      return

    .done()
    return

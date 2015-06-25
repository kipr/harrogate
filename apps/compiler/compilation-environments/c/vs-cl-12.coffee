Fs = require 'fs'
Path = require 'path'

exec = require('child_process').exec

copyFile = (source, target, cb) ->
  cbCalled = false
  rd = Fs.createReadStream(source)

  done = (err) ->
    if !cbCalled
      cb err
      cbCalled = true
    return

  rd.on 'error', (err) ->
    done err
    return
  wr = Fs.createWriteStream(target)
  wr.on 'error', (err) ->
    done err
    return
  wr.on 'close', (ex) ->
    done()
    return
  rd.pipe wr
  return

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

      #aurora
      aurora_base_path = Path.resolve __dirname, '..', '..', '..', '..', '..' , 'libaurora', 'build', 'install'
      aurora_include_path = Path.resolve aurora_base_path, 'include'
      aurora_lib_path = Path.resolve aurora_base_path, 'lib', 'aurora.lib'
      aurora_bin_path = Path.resolve aurora_base_path, 'bin', 'aurora.dll'
      cl_cmd += "/I\"#{aurora_include_path}\"
                 /Fe\"#{project_resource.bin_directory.path}\\#{project_resource.name}\" "

      for src in src_files
        cl_cmd += "\"#{src.path}\" "

      #linker options
      cl_cmd += "/link #{aurora_lib_path}"

      exec 'vs-cl-12.bat ' + cl_cmd, {cwd: Path.resolve(__dirname)}, cb

      return

    .catch (e) ->
      cb e
      return

    .done()
    return
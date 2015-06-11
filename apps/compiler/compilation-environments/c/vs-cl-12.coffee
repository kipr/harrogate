exec = require('child_process').exec

module.exports =

  compile: (project_resource, cb) ->
    project_resource.src_directory.is_valid()

    .then (valid) ->
      if not valid
        throw new ServerError 404, 'Project ' + project_resource.name + ' does not contain any source files'

      return project_resource.src_directory.get_children()

    .then (src_files) ->
      cl_cmd = "/I\"#{project_resource.include_directory.path}\"
                /Fe\"#{project_resource.bin_directory.path}\\#{project_resource.name}\" "
      for src in src_files
        cl_cmd += "\"#{src.path}\" "

      exec 'vs-cl-12.bat ' + cl_cmd, {cwd: __dirname}, cb
      return

    .catch (e) ->
      cb e
      return

    .done()
    return
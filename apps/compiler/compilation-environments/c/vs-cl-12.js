var Fs, Path, exec, install_prefix;

Fs = require('fs');

Path = require('path');

exec = require('child_process').exec;

// assume that the install prefix of the kipr libraries is <harrogate>/../prefix/usr
install_prefix = Path.resolve(Path.resolve(__dirname, '..', '..', '..', '..', '..', 'prefix', 'usr'));

module.exports = {
  compile: function(project_resource, cb) {
    project_resource.src_directory.is_valid().then(function(valid) {
      if (!valid) {
        throw new ServerError(404, 'Project ' + project_resource.name + ' does not contain any source files');
      }
      return project_resource.src_directory.get_children();
    }).then(function(src_files) {
      var cl_cmd, i, len, src;

      // compiler options
      cl_cmd = "/I\"" + project_resource.include_directory.path + "\" /Fe\"" + project_resource.bin_directory.path + "\\" + project_resource.name + "\" ";

      // Add KIPR libraries include paths
      cl_cmd += "/I\"" + (Path.resolve(install_prefix, 'include')) + "\" ";
      for (i = 0, len = src_files.length; i < len; i++) {
        src = src_files[i];
        cl_cmd += "\"" + src.path + "\" ";
      }

      // add the init helper file
      cl_cmd += "\"" + (Path.resolve(__dirname, '_init_helper.c')) + "\" ";
      exec('vs-cl-12.bat ' + cl_cmd, {
        cwd: Path.resolve(__dirname)
      }, cb);
    })["catch"](function(e) {
      cb(e);
    }).done();
  }
};

var Config, Path, exec;

exec = require('child_process').exec;

Path = require('path');

Config = require_harrogate_module('config.js');

module.exports = {
  compile: function(project_resource, cb) {
    project_resource.src_directory.is_valid().then(function(valid) {
      if (!valid) {
        throw new ServerError(404, 'Python Project ' + project_resource.name + ' does not contain any source files');
      }
      return project_resource.src_directory.get_children();
    }).then(function(src_files) {
      var chmod_cmd, cp_cmd, i, len, ln_cmd, pyc_cmd, src;
      cp_cmd = "cp ";
      pyc_cmd = "python -m py_compile ";
      for (i = 0, len = src_files.length; i < len; i++) {
        src = src_files[i];
        if (Path.basename(src.path).charAt(0) !== '.') {
          cp_cmd += '"' + src.path + "\" ";
          pyc_cmd += ("\"" + project_resource.bin_directory.path + "/") + src.name + "\" ";
        }
      }
      cp_cmd += " \"" + project_resource.bin_directory.path + "/\" ";
      ln_cmd = "ln -s \"" + project_resource.bin_directory.path + "/main.py\" \"" + project_resource.binary.path + "\"";
      chmod_cmd = "chmod u+x \"" + project_resource.binary.path + "\"";
      exec(cp_cmd);
      exec(ln_cmd);
      exec(chmod_cmd);
      exec(pyc_cmd, cb);
    })["catch"](function(e) {
      cb(e);
    }).done();
  }
};

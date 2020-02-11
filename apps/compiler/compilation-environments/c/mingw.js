var Config, Path, ServerError, exec;

exec = require('child_process').exec;

Path = require('path');

Config = require_harrogate_module('config.js');

ServerError = require_harrogate_module('shared/scripts/server-error.js');

module.exports = {
  compile: function(project_resource, cb) {
    project_resource.src_directory.is_valid().then(function(valid) {
      if (!valid) {
        throw new ServerError(404, 'Project ' + project_resource.name + ' does not contain any source files');
      }
      return project_resource.src_directory.get_children();
    }).then(function(src_files) {
      var gcc_cmd, i, len, src;
      gcc_cmd = "\"" + __dirname + "\\mingw.bat\" \"" + Config.ext_deps.min_gw.bin_path + "\" -I\"" + project_resource.include_directory.path + "\" -I\"" + Config.ext_deps.include_path + "\" -g -Wall ";
      for (i = 0, len = src_files.length; i < len; i++) {
        src = src_files[i];
        if (Path.basename(src.path).charAt(0) !== '.') {
          gcc_cmd += '"' + src.path + "\" ";
        }
      }

      // add the init helper file
      gcc_cmd += "\"" + (Path.resolve(__dirname, '_init_helper.c')) + "\" ";

      // linker options
      gcc_cmd += "-L\"" + Config.ext_deps.lib_path + "\" -o \"" + project_resource.binary.path + ".exe\" -lpthread ";
      exec(gcc_cmd, cb);
    })["catch"](function(e) {
      cb(e);
    }).done();
  }
};

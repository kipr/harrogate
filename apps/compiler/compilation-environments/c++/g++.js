var Config, Path, exec;

exec = require('child_process').exec;

Path = require('path');

Config = require_harrogate_module('config.js');

const fs = require("fs");

module.exports = {
  compile: function (project_resource, cb) {
    project_resource.src_directory.is_valid().then(function (valid) {
      if (!valid) {
        throw new ServerError(404, 'Project ' + project_resource.name + ' does not contain any source files');
      }
      return project_resource.src_directory.get_children();
    }).then(function (src_files) {
      var gpp_cmd, i, len, src;
      gpp_cmd = "g++ -I\"" + project_resource.include_directory.path + "\" -I\"" + Config.ext_deps.include_path + "\" -Wall ";
      for (i = 0, len = src_files.length; i < len; i++) {
        src = src_files[i];
        if (Path.basename(src.path).charAt(0) !== '.') {
          gpp_cmd += '"' + src.path + "\" ";
        }
      }
      gpp_cmd += "-L\"" + Config.ext_deps.lib_path + "\" -lkipr -lm -o \"" + project_resource.binary.path + "\" -lz -lpthread ";

      // extra support for extra compiler args
      if (fs.existsSync(project_resource.data_directory.path + "/config.json")) {
        try {
          options = JSON.parse(fs.readFileSync(project_resource.data_directory.path + "/config.json", { encoding: 'ascii', flag: 'r' }));

          if ("compilerArgs" in options) {
            options["compilerArgs"].forEach(element => {
              gpp_cmd += element + " ";
            });
          }
        }
        catch (e) {
          console.log("failed because of");
          console.log(e);
        }
      }

      exec(gpp_cmd, cb);
    })["catch"](function (e) {
      cb(e);
    }).done();
  }
};

var AppCatalog, AppManifest, Directory, File, Fs, FsApp, Path, Project, Q, ServerError, Tar, Workspace,
  bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

Fs = require('fs');

Path = require('path');

Q = require('q');

Tar = require('tar-stream');

AppCatalog = require_harrogate_module('/shared/scripts/app-catalog.js');

Project = require('./project.js');

ServerError = require_harrogate_module('/shared/scripts/server-error.js');

FsApp = AppCatalog.catalog['Host Filesystem'].get_instance();

Directory = require(AppCatalog.catalog['Host Filesystem'].path + '/directory.js');

File = require(AppCatalog.catalog['Host Filesystem'].path + '/file.js');

AppManifest = require('./manifest.json');

Workspace = (function() {
  function Workspace(ws_directory) {
    this.ws_directory = ws_directory;
    this.create_project = bind(this.create_project, this);
    this.import_from_archive = bind(this.import_from_archive, this);
    this.init = bind(this.init, this);
    this.get_representation = bind(this.get_representation, this);
    this.get_projects = bind(this.get_projects, this);
    this.get_project = bind(this.get_project, this);
    this.is_valid = bind(this.is_valid, this);
    this.uri = AppManifest.web_api.projects.uri;
    this.include_directory = Directory.create_from_path(Path.join(this.ws_directory.path, 'include'));
    this.src_directory = Directory.create_from_path(Path.join(this.ws_directory.path, 'src'));
    this.data_directory = Directory.create_from_path(Path.join(this.ws_directory.path, 'data'));
    this.bin_directory = Directory.create_from_path(Path.join(this.ws_directory.path, 'bin'));
    this.lib_directory = Directory.create_from_path(Path.join(this.ws_directory.path, 'lib'));
  }

  Workspace.prototype.is_valid = function() {
    return Q.all([this.ws_directory.is_valid(), this.include_directory.is_valid(), this.src_directory.is_valid(), this.data_directory.is_valid(), this.bin_directory.is_valid(), this.lib_directory.is_valid()]).then(function(values) {
      return values.reduce(function(previousValue, currentValue) {
        return previousValue && currentValue;
      });
    });
  };

  Workspace.prototype.get_project = function(name) {
    return this.get_projects().then((function(_this) {
      return function(projects) {
        var project;
        project = ((function() {
          var i, len, results;
          results = [];
          for (i = 0, len = projects.length; i < len; i++) {
            project = projects[i];
            if (project.name === name) {
              results.push(project);
            }
          }
          return results;
        })())[0];
        if (project == null) {
          throw new ServerError(404, 'This workspace does not contain a project named ' + name);
        }
        return project;
      };
    })(this));
  };

  Workspace.prototype.get_projects = function() {
    // a project has at least a project file *.project.json located in the workspace root
    return this.ws_directory.get_children().then((function(_this) {
      return function(children) {
        var child, project_resources;
        // create the project resources (exclude non-folders)
        return project_resources = ((function() {
          var i, len, results;
          results = [];
          for (i = 0, len = children.length; i < len; i++) {
            child = children[i];
            if (child instanceof File) {
              results.push(child);
            }
          }
          return results;
        })()).map(function(child) {
          var project_name;
          project_name = child.name.slice(0, -13);
          return new Project(project_name, child, Directory.create_from_path(Path.join(_this.include_directory.path, project_name)), Directory.create_from_path(Path.join(_this.src_directory.path, project_name)), Directory.create_from_path(Path.join(_this.data_directory.path, project_name)), Directory.create_from_path(Path.join(_this.bin_directory.path, project_name)), Directory.create_from_path(Path.join(_this.lib_directory.path, project_name)));
        });
      };
    })(this));
  };

  Workspace.prototype.get_representation = function() {
    var representation;
    representation = {
      links: {
        self: {
          href: this.uri
        },
        ws_directory: {
          href: this.ws_directory.uri
        },
        include_directory: {
          href: this.include_directory.uri
        },
        src_directory: {
          href: this.src_directory.uri
        },
        data_directory: {
          href: this.data_directory.uri
        },
        bin_directory: {
          href: this.bin_directory.uri
        },
        lib_directory: {
          href: this.lib_directory.uri
        }
      }
    };
    // get the projects
    return this.get_projects().then((function(_this) {
      return function(project_resources) {
        // get the representation of all project resources
        return Q.allSettled(project_resources.map(function(project_resource) {
          return project_resource.get_representation(false);
        }));
      };
    })(this)).then((function(_this) {
      return function(project_representation_promises) {
        var promise;
        // add the projects (just the valid ones)
        representation.projects = (function() {
          var i, len, results;
          results = [];
          for (i = 0, len = project_representation_promises.length; i < len; i++) {
            promise = project_representation_promises[i];
            if (promise.state === 'fulfilled') {
              results.push(promise.value);
            }
          }
          return results;
        })();
        return representation;
      };
    })(this));
  };

  Workspace.prototype.init = function() {};

  Workspace.prototype.import_from_archive = function(pack) {
    return Q.Promise((function(_this) {
      return function(resolve, reject, notify) {
        var extract;
        extract = Tar.extract();
        extract.on('entry', function(header, stream, callback) {
          var file_name, project_name, ref, type, type_root_directory_resource;
          ref = header.name.split('/'), project_name = ref[0], type = ref[1], file_name = ref[2];
          // skip this file if any of project_name, type, file_name is not set
          if ((project_name == null) || (type == null) || (file_name == null)) {
            callback();
            return;
          }
          type_root_directory_resource = (function() {
            switch (type) {
              case 'include':
                return this.include_directory;
              case 'src':
                return this.src_directory;
              case 'data':
                return this.data_directory;
            }
          }).call(_this);
          if (type_root_directory_resource == null) {
            callback();
            return;
          }
          return type_root_directory_resource.is_valid().then(function(valid) {
            // create <ws>/<type> if it doesn't exist
            if (!valid) {
              return Q.nfcall(Fs.mkdir, type_root_directory_resource.path);
            } else {
              return Q(void 0);
            }
          }).then(function() {
            // get the project resource
            return _this.get_project(project_name);
          }).then((function(project_resource) {
            // the project already exist
            return project_resource;
          }), function(error) {
            if (((error != null ? error.code : void 0) != null) && error.code === 404) {
              // the project does not exist yet, create it
              return _this.create_project(project_name, 'C');
            } else {
              // some other error happended, rethrow
              throw error;
            }
          }).then(function(project_resource) {
            var directory_resource;
            // get the directory resource and check if it is valid (= existing)
            directory_resource = (function() {
              switch (type) {
                case 'include':
                  return project_resource.include_directory;
                case 'src':
                  return project_resource.src_directory;
                case 'data':
                  return project_resource.data_directory;
              }
            })();
            return [Q(directory_resource), directory_resource.is_valid()];
          }).spread(function(directory_resource, valid) {
            // create <ws>/<type> if it doesn't exist
            return [Q(directory_resource), !valid ? Q.nfcall(Fs.mkdir, directory_resource.path) : Q(void 0)];
          }).spread(function(directory_resource) {
            var fs_write_stream;
            // create the file
            fs_write_stream = Fs.createWriteStream(Path.join(directory_resource.path, file_name));
            stream.pipe(fs_write_stream);
            return stream.on('end', function() {
              return callback();
            });
          })["catch"](function(error) {
            // an error happened, continue with the next file
            console.log("Unexpected error while importing " + project_name + "/" + type + "/" + file_name);
            console.log(error);
            return callback();
          }).done();
        });
        extract.on('error', function(error) {
          return reject(error);
        });
        extract.on('finish', function() {
          return resolve();
        });
        return pack.pipe(extract);
      };
    })(this));
  };

  Workspace.prototype.create_project = function(name, language, src_file_name) {
    var content;
    if (src_file_name == null) {
      src_file_name = 'main.c';
    }
    // create the project file
    content = JSON.stringify({
      language: language
    });
    return this.ws_directory.create_file(name + '.project.json', content, 'ascii').then((function(_this) {
      return function(project_file) {
        return new Project(name, project_file, Directory.create_from_path(Path.join(_this.include_directory.path, name)), Directory.create_from_path(Path.join(_this.src_directory.path, name)), Directory.create_from_path(Path.join(_this.data_directory.path, name)), Directory.create_from_path(Path.join(_this.bin_directory.path, name)), Directory.create_from_path(Path.join(_this.lib_directory.path, name)));
      };
    })(this)).then((function(_this) {
      return function(project_resource) {
        return project_resource.src_directory.create().then(function() {
          if (language === 'Python') {
            content = "#!/usr/bin/python\nimport os, sys\nfrom wallaby import *\n\ndef main():\n    print \"Hello World\"\n\nif __name__==\"__main__\":\n    sys.stdout = os.fdopen(sys.stdout.fileno(),'w',0)\n    main()";
          } else {
            content = "#include <kipr/botball.h>\n        \nint main()\n{\n    printf(\"Hello World\\n\");\n    return 0;\n}";
          }
          return project_resource.src_directory.create_file(src_file_name, content, 'ascii').then(function() {
            return project_resource;
          });
        });
      };
    })(this));
  };

  return Workspace;

})();

module.exports = Workspace;

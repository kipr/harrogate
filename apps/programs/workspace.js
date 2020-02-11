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

    this.users = ['Default User'];
    var users_path = Path.join(this.ws_directory.path, 'users.json');

    try {
      this.users = JSON.parse(Fs.readFileSync(users_path, 'utf8'));
    } catch(e) {}

    if(this.users.constructor === Array)
    {
      var new_users = {};
      this.users.forEach(function(user) {
        new_users[user] = {
          mode: "Simple"
        };
      });
      this.users = new_users;
    }
  }

  Workspace.prototype.is_valid = function() {
    return Q.all([this.ws_directory.is_valid()]).then(function(values) {
      return values.reduce(function(previousValue, currentValue) {
        return previousValue && currentValue;
      });
    });
  };

  Workspace.prototype.get_project = function(user, name) {
    user = user || 'Default User';
    return this.get_projects(user).then((function(_this) {
      return function(projects) {
        var project;
        project = ((function() {
          var i, len, results;
          results = [];
          for (i = 0, len = projects.length; i < len; i++) {
            project = projects[i];
            var user_valid = !user || user === project.user;
            if (project.name === name && user_valid) {
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

  Workspace.prototype.sync_users = function() {
    const file = Path.join(this.ws_directory.path, 'users.json');
    Fs.writeFileSync(file, JSON.stringify(this.users));
  }

  Workspace.prototype.update_user = function(user, data) {
    if(!(user in this.users)) return;
    this.users[user] = data;
    this.sync_users();
  }

  Workspace.prototype.add_user = function(user) {
    if(user in this.users) return;
    this.users[user] = {
      mode: "Simple"
    };
    this.sync_users();
    console.log("ADD USER!!!!!!!!!!!!");
  }

  Workspace.prototype.remove_user = function(user) {
    if(user === 'Default User') return;
    if(!(user in this.users)) return;
    delete this.users[user];
    
    var dir = Directory.create_from_path(Path.join(this.ws_directory.path, user));
    this.sync_users();
    return dir.remove();
  }

  Workspace.prototype.get_projects = function(user) {
    user = user || 'Default User';
    // a project has at least a project file *.project.json located in the workspace root
    return this.ws_directory.get_children().then(function(children) {
      // create the project resources (exclude non-folders)
      return Q.all(children.filter(function (user_dir) {
        return user_dir instanceof Directory;
      }).map(function (user_dir) {
        return user_dir.get_children().then(function (projects) {
          var ret = {
            user: user_dir.name,
            projects: projects
          };
          return ret;
        });
      })).then(function (users) {
        var user_projects = users.filter(function (o) {
          return o.user === user;
        })[0] || {projects: []};

        return user_projects.projects.map(function (child) {
          return new Project(child.name,
            File.create_from_path(Path.join(child.path, 'project.manifest')),
            Directory.create_from_path(Path.join(child.path, 'include')),
            Directory.create_from_path(Path.join(child.path, 'src')),
            Directory.create_from_path(Path.join(child.path, 'data')),
            Directory.create_from_path(Path.join(child.path, 'bin')),
            Directory.create_from_path(Path.join(child.path, 'lib')));
        });
      });
    });
  };

  Workspace.prototype.get_representation = function(user) {
    var representation;
    representation = {
      links: {
        self: {
          href: this.uri
        },
        ws_directory: {
          href: this.ws_directory.uri
        }
      }
    };
    // get the projects
    return this.get_projects(user).then(function(project_resources) {
      // get the representation of all project resources
      return Q.allSettled(project_resources.map(function(project_resource) {
        return project_resource.get_representation(true);
      }));
    }).then(function(project_representation_promises) {
      // add the projects (just the valid ones)

      return project_representation_promises
        .filter(function(promise) { return promise.state === 'fulfilled'; })
        .map(function(promise) { return promise.value; });
    }).then(function(values) {
      representation.projects = values;
      return representation;
    });
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
              return _this.create_project('Default User', project_name, 'C');
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

  Workspace.prototype.create_project = function(user, name, language, src_file_name) {
    var content;
    if (src_file_name == null) {
      src_file_name = 'main.c';
    }
    // create the project file
    content = JSON.stringify({
      language: language,
      user: user
    });

    var programContent;
    if (language === 'Python')
    {
      programContent =  '#!/usr/bin/python\n' 
        + 'import os, sys\n'
        + 'import kipr as k\n'
        + '\n'
        + 'def main():\n'
        + '    print "Hello World"\n'
	      + '    k.motor(1, 50)\n'
      	+ '    k.msleep(5000)\n'
        + '\n'
        + 'if __name__== "__main__":\n'
        + '    sys.stdout = os.fdopen(sys.stdout.fileno(),"w",0)\n'
        + '    main();\n'; 
    }
    else
    {
      programContent = '#include <kipr/wombat.h>\n'
        + '\n'
        + 'int main()\n'
        + '{\n'
        + '    printf("Hello World\\n");\n'
        + '    return 0;\n'
        + '}\n';
    }

    return this.ws_directory.create_subdirectory(user, false).then((function (_root) {
      return function (user_dir) {
        return user_dir.create_subdirectory(name).then(function (project_dir) {
          return project_dir.create_file('project.manifest', content, 'ascii').then(function(project_file) {
            return new Project(name, project_file,
              Directory.create_from_path(Path.join(project_dir.path, 'include')),
              Directory.create_from_path(Path.join(project_dir.path, 'src')),
              Directory.create_from_path(Path.join(project_dir.path, 'data')),
              Directory.create_from_path(Path.join(project_dir.path, 'bin')),
              Directory.create_from_path(Path.join(project_dir.path, 'lib')));
          });
        }).then(function(project_resource) {
          return project_resource.include_directory.create().then(function() {
            return project_resource.data_directory.create().then(function() {
              return project_resource.src_directory.create().then(function() {
                return project_resource.src_directory.create_file(src_file_name, programContent, 'ascii').then(function() {
                  return project_resource;
                });
              });
            });
          });
        });
      };
    })(this));
  };

  return Workspace;

})();

module.exports = Workspace;

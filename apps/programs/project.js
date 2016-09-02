var AppCatalog, AppManifest, Directory, File, Fs, FsApp, Path, Project, Q, TargetApp, _, delete_directory_helper, get_file_representations, pack_helper,
  bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

Fs = require('fs');

Path = require('path');

Q = require('q');

_ = require('lodash');

AppCatalog = require_harrogate_module('/shared/scripts/app-catalog.js');

FsApp = AppCatalog.catalog['Host Filesystem'].get_instance();

Directory = require(AppCatalog.catalog['Host Filesystem'].path + '/directory.js');

File = require(AppCatalog.catalog['Host Filesystem'].path + '/file.js');

TargetApp = AppCatalog.catalog['Target information'].get_instance();

AppManifest = require('./manifest.json');

get_file_representations = function(directory) {
  return directory.is_valid().then((function(_this) {
    return function(valid) {
      if (!valid) {
        return Q(void 0);
      } else {
        return directory.get_children().then(function(children) {
          // get the compact representation of all resources
          return Q.allSettled(children.map(function(child) {
            return child.get_representation(false);
          }));
        }).then(function(child_representation_promises) {
          var promise;
          return (function() {
            var i, len, results;
            results = [];
            for (i = 0, len = child_representation_promises.length; i < len; i++) {
              // add the children
              promise = child_representation_promises[i];
              if (promise.state === 'fulfilled') {
                results.push(promise.value);
              }
            }
            return results;
          })();
        });
      }
    };
  })(this));
};

delete_directory_helper = function(directory) {
  return directory.is_valid().then((function(_this) {
    return function(valid) {
      if (valid) {
        return directory.remove();
      } else {
        return Q(void 0);
      }
    };
  })(this));
};

pack_helper = function(pack, folder_resource, prefix) {
  return folder_resource.is_valid().then(function(valid) {
    if (valid) {
      return folder_resource.get_children();
    } else {
      return Q(void 0);
    }
  }).then(function(children) {
    var child, i, len, promises;
    if (children != null) {
      promises = [];
      for (i = 0, len = children.length; i < len; i++) {
        child = children[i];
        promises.push(Q.Promise(function(resolve, reject, notify) {
          var name;
          name = prefix + "/" + child.name;
          pack.file(child.path, {name: name});
          return resolve(child);
        }));
      }
      return Q.all(promises);
    } else {
      return Q(void 0);
    }
  });
};

Project = (function() {
  function Project(name1, project_file, include_directory, src_directory, data_directory, bin_directory, lib_directory) {
    var binary_path;
    this.name = name1;
    this.project_file = project_file;
    this.include_directory = include_directory;
    this.src_directory = src_directory;
    this.data_directory = data_directory;
    this.bin_directory = bin_directory;
    this.lib_directory = lib_directory;
    this.get_representation = bind(this.get_representation, this);
    this.pack = bind(this.pack, this);
    this.remove = bind(this.remove, this);
    this.is_valid = bind(this.is_valid, this);
    
    binary_path = Path.resolve(this.bin_directory.path, 'botball_user_program');
    if (TargetApp.platform === TargetApp.supported_platforms.WINDOWS_PC) {
      binary_path += '.exe';
    }
    this.binary = File.create_from_path(binary_path);
  }

  Project.prototype.is_valid = function() {
    return this.project_file.is_valid();
  };

  Project.prototype.remove = function() {
    return this.project_file.get_parent().then(function (parent) {
      return delete_directory_helper(parent);
    });
  };

  Project.prototype.pack = function(pack) {
    return Q.all([
      pack_helper(pack, this.include_directory, this.name + "/include"),
      pack_helper(pack, this.src_directory, this.name + "/src"),
      pack_helper(pack, this.data_directory, this.name + "/data")
    ]);
  };

  Project.prototype.get_representation = function(verbose) {
    var representation;
    if (verbose == null) {
      verbose = true;
    }
    representation = {
      name: this.name,
      links: {}
    };
    if(!verbose)
      console.log('verbose?', verbose);
    if (verbose) {
      _.merge(representation, {
        links: {
          project_file: {
            href: this.project_file.uri
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
          binary: {
            href: this.binary.uri
          },
          lib_directory: {
            href: this.lib_directory.uri
          }
        }
      });
    }

    return Q.nfcall(Fs.readFile, this.project_file.path).then((function(_this) {
      // >>> Async part. Return a promise and continue
      // get the .project.json file content
      return function(content) {
        var project_parameters;
        project_parameters = JSON.parse(content);

        representation.links.self = {
          href: AppManifest.web_api.projects.uri
            + '/' + encodeURIComponent(project_parameters.user)
            + '/' + encodeURIComponent(_this.name)
        };
        

        if (!verbose) {
          // just add the project language and owner and return
          representation.parameters = {
            language: project_parameters.language,
            user: project_parameters.user
          };
          return representation;
        } else {
          // add the all parameters
          representation.parameters = project_parameters;
          
          // add all the project files
          return Q.all([
            get_file_representations(_this.include_directory),
            get_file_representations(_this.src_directory),
            get_file_representations(_this.data_directory),
            get_file_representations(_this.bin_directory),
            get_file_representations(_this.lib_directory)
          ]).then(function(values) {
            if (values[0] != null) {
              representation.include_files = values[0];
            }
            if (values[1] != null) {
              representation.source_files = values[1];
            }
            if (values[2] != null) {
              representation.data_files = values[2];
            }
            if (values[3] != null) {
              representation.binary_files = values[3];
            }
            if (values[4] != null) {
              representation.library_files = values[4];
            }
            // finally done
            return representation;
          });
        }
      };
    })(this));
  };

  return Project;

})();

module.exports = Project;

var AppCatalog, Directory, FS, HostFileSystem, Path, Q, Rmdir, ServerError, TargetApp,
  bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

FS = require('fs');

Path = require('path');

Rmdir = require('rimraf');

Q = require('q');

AppCatalog = require_harrogate_module('/shared/scripts/app-catalog.js');

HostFileSystem = require('./host-fs.js');

ServerError = require_harrogate_module('/shared/scripts/server-error.js');

TargetApp = AppCatalog.catalog['Target information'].get_instance();

Directory = (function() {
  function Directory(uri) {
    this.uri = uri;
    this.remove = bind(this.remove, this);
    this.create_subdirectory = bind(this.create_subdirectory, this);
    this.create = bind(this.create, this);
    this.create_file = bind(this.create_file, this);
    this.get_representation = bind(this.get_representation, this);
    this.is_valid = bind(this.is_valid, this);
    this.get_children = bind(this.get_children, this);
    this.get_child = bind(this.get_child, this);
    this.get_parent = bind(this.get_parent, this);
    this.path = HostFileSystem.uri_2_path(this.uri);
    if (TargetApp.platform === TargetApp.supported_platforms.WINDOWS_PC && this.path === '') {
      this.name = 'This PC';
    } else {
      this.name = this.path.slice(-2) === (':' + Path.sep) ? this.path : Path.basename(this.path);
    }
  }

  Directory.create_from_path = function(path) {
    return new this(HostFileSystem.path_2_uri(path));
  };

  Directory.prototype.get_parent = function() {
    // >>> Async part. Return a promise and continue
    // check if the resource is valid
    return this.is_valid().then((function(_this) {
      return function(valid) {
        var parent_path;
        // throw an error if it's not valid
        if (!valid) {
          throw new ServerError(400, _this.path + ' is not a directory');
        }
        // 'this PC' special case
        if (_this.path === '') {
          // 'this PC' resource has no parent
          return Q(void 0);
        }
        // Windows drive letter special case
        if (TargetApp.platform === TargetApp.supported_platforms.WINDOWS_PC && (_this.path.slice(-2) === (':' + Path.sep))) {
          return Directory.create_from_path('');
        }
        parent_path = Path.dirname(_this.path);
        if (parent_path === _this.path) {
          return Q(void 0);
        } else {
          return Directory.create_from_path(parent_path);
        }
      };
    })(this));
  };

  Directory.prototype.get_child = function(name) {
    return this.get_children().then((function(_this) {
      return function(children) {
        var child;
        child = ((function() {
          var i, len, results;
          results = [];
          for (i = 0, len = children.length; i < len; i++) {
            child = children[i];
            if (child.name === name) {
              results.push(child);
            }
          }
          return results;
        })())[0];
        if (child == null) {
          throw new ServerError(404, name + ' is not a child of ' + _this.path);
        }
        return child;
      };
    })(this));
  };

  Directory.prototype.get_children = function() {
    var drive_letter, promise;
    if (TargetApp.platform === TargetApp.supported_platforms.WINDOWS_PC && this.path === '') {
      // Children = windows drive letters
      promise = Q((function() {
        var i, len, ref, results;
        ref = HostFileSystem.win_drive_letters;
        results = [];
        for (i = 0, len = ref.length; i < len; i++) {
          drive_letter = ref[i];
          results.push(drive_letter + Path.sep);
        }
        return results;
      })());
    } else {
      // # Children = @path/*
      promise = Q.nfcall(FS.readdir, this.path);
    }
    return promise.then((function(_this) {
      return function(children) {
        // get a list of all children; allSettled bc not all children (e.g. Floppy) might be accessible
        return Q.allSettled(children.map(function(child_name) {
          var path;
          if (_this.path.slice(-1) === Path.sep || _this.path === '') {
            path = _this.path;
          } else {
            path = _this.path + Path.sep;
          }
          return HostFileSystem.open(path + child_name);
        }));
      };
    })(this)).then((function(_this) {
      // ignore rejected promises; return fulfilled as array
      return function(child_resource_promises) {
        return (function() {
          var i, len, results;
          results = [];
          for (i = 0, len = child_resource_promises.length; i < len; i++) {
            promise = child_resource_promises[i];
            if (promise.state === 'fulfilled') {
              results.push(promise.value);
            }
          }
          return results;
        })();
      };
    })(this));
  };

  Directory.prototype.is_valid = function() {
    // 'this PC' is always valid
    if (TargetApp.platform === TargetApp.supported_platforms.WINDOWS_PC && this.path === '') {
      return Q(true);
    }

    // else check the stats
    return Q.nfcall(FS.stat, this.path).then((function(stats) {
      if (stats.isDirectory()) {
        return Q(true);
      } else {
        return Q(false);
      }
    }), function(err) {
      return Q(false);
    });
  };

  Directory.prototype.get_representation = function(verbose) {
    var representation;
    if (verbose == null) {
      verbose = true;
    }
    representation = {
      name: this.name,
      type: 'Directory',
      links: {
        self: {
          href: this.uri
        }
      }
    };

    // add path (not for 'This PC')
    if (!(TargetApp.platform === TargetApp.supported_platforms.WINDOWS_PC && this.path === '')) {
      representation.path = this.path;
    }

    // >>> Async part. Return a promise and continue
    // check if the resource is valid
    return this.is_valid().then((function(_this) {
      return function(valid) {
        // throw an error if it's not valid
        if (!valid) {
          throw new ServerError(400, _this.path + ' is not a directory');
        }
        if (!verbose) {
          // we are done if we don't have to include parent / children
          return Q(representation);
        } else {
          // get the parent resource
          return _this.get_parent().then(function(parent_resource) {
            if (parent_resource != null) {
              // resource has a parent, add it
              return parent_resource.get_representation(false);
            } else {
              // there is no parent
              return Q(void 0);
            }
          }).then(function(parent_representation) {
            // Add the parent representation
            representation.parent = parent_representation;

            // get the children
            return _this.get_children();
          }).then(function(child_resources) {
            // get the compact representation of all resources
            return Q.allSettled(child_resources.map(function(child_resource) {
              return child_resource.get_representation(false);
            }));
          }).then(function(child_representation_promises) {
            // add the children
            var promise;
            representation.children = (function() {
              var i, len, results;
              results = [];
              for (i = 0, len = child_representation_promises.length; i < len; i++) {
                promise = child_representation_promises[i];
                if (promise.state === 'fulfilled') {
                  results.push(promise.value);
                }
              }
              return results;
            })();
            // finally done
            return Q(representation);
          });
        }
      };
    })(this));
  };

  Directory.prototype.create_file = function(name, content, encoding) {
    var child_path;
    // Handle 'This PC'
    if (TargetApp.platform === TargetApp.supported_platforms.WINDOWS_PC && this.path === '') {
      throw new ServerError(403, 'Cannot create a file in \'This PC\'');
    }

    // compose the child path
    child_path = Path.join(this.path, name);

    // >>> Async part. Return a promise and continue
    // check if the resource is valid
    return this.is_valid().then((function(_this) {
      return function(valid) {
        // throw an error if it's not valid
        if (!valid) {
          throw new ServerError(400, _this.path + ' is not a directory');
        }
        // get the stats (we can as 'this pc' is already handled)
        return Q.nfcall(FS.stat, child_path);
      };
    })(this)).then(((function(_this) {
      return function(stats) {
        // file does exist --> error
        throw new ServerError(409, name + ' already exists');
      };
    })(this)), (function(_this) {
      return function(err) {
        var File, file_resource;
        if (err.code !== 'ENOENT') {
          // error is not ENOENT --> something happended --> error
          throw new ServerError(500, 'Unable to open ' + child_path);
        }

        // get the file resource
        // we have to require File here to avoid circular dependency issues
        File = require('./file.js');
        file_resource = File.create_from_path(child_path);
        // create the file
        return file_resource.write(content, encoding).then(function() {
          // return the file resource once the write has finished
          return file_resource;
        });
      };
    })(this));
  };

  Directory.prototype.create = function() {
    // Handle 'This PC'
    if (TargetApp.platform === TargetApp.supported_platforms.WINDOWS_PC && this.path === '') {
      throw new ServerError(403, 'Cannot create \'This PC\'');
    }
    // >>> Async part. Return a promise and continue
    // create the directory
    return Q.nfcall(FS.mkdir, this.path).then((function(_this) {
      return function() {
        // directory created, return resource
        return _this;
      };
    })(this));
  };

  Directory.prototype.create_subdirectory = function(name, error_on_exists) {
    var child_path;
    if(typeof error_on_exists === 'undefined') error_on_exists = true;
    console.log('error_on_exists', error_on_exists);
    
    // Handle 'This PC'
    if (TargetApp.platform === TargetApp.supported_platforms.WINDOWS_PC && this.path === '') {
      throw new ServerError(403, 'Cannot create a file or directory in \'This PC\'');
    }

    // compose the child path
    child_path = Path.join(this.path, name);
    var path = this.path;

    // >>> Async part. Return a promise and continue
    // check if the resource is valid
    return this.is_valid().then(function(valid) {
      // throw an error if it's not valid
      if (!valid) {
        throw new ServerError(400, path + ' is not a directory');
      }
      // get the stats (we can as 'this pc' is already handled)
      return Q.nfcall(FS.stat, child_path);
    }).then(function(stats) {
      if(error_on_exists) throw new ServerError(409, name + ' already exists');
      return Directory.create_from_path(child_path);
    }, function(err) {
      if (err.code !== 'ENOENT') {
        // error is not ENOENT --> something happended --> error
        throw new ServerError(500, 'Unable to open ' + child_path + ' ('  + err + ')');
      }
      
      // create the directory
      return Q.nfcall(FS.mkdir, child_path).then(function() {
        return Directory.create_from_path(child_path);
      });
    });
  };

  Directory.prototype.remove = function() {
    var deferred;
    deferred = Q.defer();
    Rmdir(this.path, (function(_this) {
      return function(error) {
        if (error) {
          return deferred.reject(new ServerError(403, 'Unable to delete ' + _this.path));
        } else {
          return deferred.resolve();
        }
      };
    })(this));
    return deferred.promise;
  };

  return Directory;

})();

module.exports = Directory;

var AppCatalog, FS, File, HostFileSystem, Mime, Path, Q, ServerError, TargetApp,
  bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

FS = require('fs');

Path = require('path');

Q = require('q');

Mime = require('mime');

AppCatalog = require_harrogate_module('/shared/scripts/app-catalog.js');

HostFileSystem = require('./host-fs.js');

ServerError = require_harrogate_module('/shared/scripts/server-error.js');

TargetApp = AppCatalog.catalog['Target information'].get_instance();

File = (function() {
  function File(uri) {
    this.uri = uri;
    this.remove = bind(this.remove, this);
    this.write = bind(this.write, this);
    this.get_representation = bind(this.get_representation, this);
    this.is_valid = bind(this.is_valid, this);
    this.get_parent = bind(this.get_parent, this);
    this.path = HostFileSystem.uri_2_path(this.uri);
    this.name = Path.basename(this.path);
  }

  File.create_from_path = function(path) {
    return new this(HostFileSystem.path_2_uri(path));
  };


  File.prototype.get_parent = function() {
    // >>> Async part. Return a promise and continue
    // check if the resource is valid
    return this.is_valid().then((function(_this) {
      return function(valid) {
        var Directory;
        // throw an error if it's not valid
        if (!valid) {
          throw new ServerError(400, _this.path + ' is not a file');
        }

        // if our is_valid works, parent_path should be always defined and points to a directory
        // we have to require Directory here to avoid circular dependency issues
        Directory = require('./directory.js');
        return Directory.create_from_path(Path.dirname(_this.path));
      };
    })(this));
  };

  File.prototype.is_valid = function() {
    // 'this PC' is not a valid file
    if (TargetApp.platform === TargetApp.supported_platforms.WINDOWS_PC && this.path === '') {
      return Q(false);
    }
    // else check the stats
    return Q.nfcall(FS.stat, this.path).then((function(stats) {
      // it exists; is it a directory?
      if (stats.isFile()) {
        return Q(true);
      } else {
        return Q(false);
      }
    }), function(err) {
      return Q(false);
    });
  };

  File.prototype.get_representation = function(verbose) {
    var representation;
    if (verbose == null) {
      verbose = true;
    }
    representation = {
      name: this.name,
      path: this.path,
      type: Mime.lookup(this.path),
      links: {
        self: {
          href: this.uri
        }
      }
    };
    return this.is_valid().then((function(_this) {
      // >>> Async part. Return a promise and continue
      // check if the resource is valid
      return function(valid) {
        if (!valid) {
          throw new ServerError(400, _this.path + ' is not a file');
        }
        if (!verbose) {
          // we are done if we don't have to include parent / content
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
            // get the content
            return Q.nfcall(FS.readFile, _this.path);
          }).then(function(content) {
            representation.content = content.toString('base64');
            // finally done
            return Q(representation);
          });
        }
      };
    })(this));
  };

  File.prototype.write = function(content, encoding) {
    if (encoding == null) {
      encoding = 'ascii';
    }
    if (content == null) {
      content = '';
    }
    return Q.nfcall(FS.writeFile, this.path, content, encoding = encoding);
  };

  File.prototype.remove = function() {
    return Q.nfcall(FS.unlink, this.path);
  };

  return File;

})();

module.exports = File;

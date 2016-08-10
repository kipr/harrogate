var AppCatalog, AppManifest, FS, HostFileSystem, Path, Q, ServerError, TargetApp, spawn,
  bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

FS = require('fs');

Path = require('path');

Q = require('q');

spawn = require('child_process').spawn;

AppCatalog = require_harrogate_module('/shared/scripts/app-catalog.js');

ServerError = require_harrogate_module('/shared/scripts/server-error.js');

TargetApp = AppCatalog.catalog['Target information'].get_instance();

AppManifest = require('./manifest.json');

HostFileSystem = (function() {
  function HostFileSystem() {
    this.open_from_path = bind(this.open_from_path, this);
    this.open_from_uri = bind(this.open_from_uri, this);
    this.open = bind(this.open, this);
    var list;
    // get the drive letters
    this.win_drive_letters = [];
    if (TargetApp.platform === TargetApp.supported_platforms.WINDOWS_PC) {
      list = spawn('cmd');
      list.stdout.on('data', (function(_this) {
        return function(data) {
          var data_str, i, len, match, matches;
          data_str = '' + data;
          matches = data_str.match(/^(.:)(?!\S)/gm);
          if (matches != null) {
            for (i = 0, len = matches.length; i < len; i++) {
              match = matches[i];
              _this.win_drive_letters.push(match);
            }
          }
        };
      })(this));
      list.stderr.on('data', function(data) {
        console.log('stderr: ' + data);
      });
      list.on('exit', function(code) {});
      list.on('error', function(data) {
        console.log("Could get the Windows drive letters! Error details: " + (JSON.stringify({
          error: data
        })));
      });
      list.stdin.write('wmic logicaldisk get name\n');
      list.stdin.end();
    }
  }

  HostFileSystem.prototype.uri_2_path = function(uri) {
    var path;

    // decode uri
    uri = decodeURI(uri);

    // uri = <AppManifest.web_api.fs.uri>/<path>
    path = uri.substr(AppManifest.web_api.fs.uri.length);

    // '/' --> os dependent path separator
    path = path.replace(/(\/)/g, Path.sep);

    // For Windows '\C:' --> C:\ 
    if (TargetApp.platform === TargetApp.supported_platforms.WINDOWS_PC) {
      path = path.substr(1);
      if (path.slice(-1) === ':') {
        path = path + Path.sep;
      }
    }
    return path;
  };

  HostFileSystem.prototype.path_2_uri = function(path) {
    var uri;

    // os dependent path separator --> '/'
    uri = path.replace(new RegExp('\\' + Path.sep, 'g'), '/');

    // <path>/ --> <path>
    if (uri.slice(-1) === '/') {
      uri = uri.slice(0, -1);
    }

    // For Windows 'C:' --> \C:
    if (TargetApp.platform === TargetApp.supported_platforms.WINDOWS_PC) {
      uri = '/' + uri;
    }

    // <path> --> <AppManifest.web_api.fs.uri>/<path>
    uri = ("" + AppManifest.web_api.fs.uri) + uri;

    return encodeURI(uri);
  };

  HostFileSystem.prototype.open = function(param) {

    // path overwrites uri
    if (param.path != null) {
      return this.open_from_path(param.path);
    }
    if (param.uri != null) {
      return this.open_from_uri(param.uri);
    }

    // fallback: param = path
    return this.open_from_path(param);
  };

  HostFileSystem.prototype.open_from_uri = function(uri) {
    return this.open_from_path(this.uri_2_path(uri));
  };

  HostFileSystem.prototype.open_from_path = function(path) {
    var Directory, File, deferred;

    // we have to require Directory and File here to avoid circular dependency issues
    Directory = require('./directory.js');
    File = require('./file.js');

    // empty path is OK for windows; and it's a directory
    if (TargetApp.platform === TargetApp.supported_platforms.WINDOWS_PC && path === '') {
      return Q(Directory.create_from_path(path));
    } else {
      // it looks like a regular path; does it exists?
      deferred = Q.defer();
      FS.stat(path, function(err, stats) {
        if (err != null) {
          deferred.reject(new ServerError(404, path + ': No such file or directory'));
          return;
        }
        // it exists; is it a file or directory?
        if (stats.isDirectory()) {
          deferred.resolve(Directory.create_from_path(path));
        } else {
          deferred.resolve(File.create_from_path(path));
        }
      });
      // return the promise that we will return a fs resource once fs.stat returns
      return deferred.promise;
    }
  };

  return HostFileSystem;

})();

module.exports = new HostFileSystem;

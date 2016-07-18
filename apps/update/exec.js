var AppCatalog, Express, Fs, Os, Path, ServerError, events, exec, is_updating, router, socket, spawn, update_on_connection;

Express = require('express');

Fs = require('fs');

Os = require('os');

Path = require('path');

exec = require('child_process').exec;

spawn = require('child_process').spawn;

AppCatalog = require_harrogate_module('/shared/scripts/app-catalog.js');

ServerError = require_harrogate_module('/shared/scripts/server-error.js');

events = AppCatalog.catalog['Update'].event_groups.update_events.events;

// update can only run once
is_updating = false;

socket = void 0;

update_on_connection = function(s) {
  if (socket != null) {
    socket.disconnect();
  }
  return socket = s;
};

router = Express.Router();

router.get('/', function(request, response, next) {
  var process;
  if (is_updating) {
    next(new ServerError(405, 'Update already in progress'));
    return;
  }
  if (Os.platform() === 'win32' || Os.platform() === 'darwin') {
    next(new ServerError(503, 'This plattform does not support update'));
    return;
  }
  // mount the fs
  return process = exec('mount /dev/sda1 /mnt', function(error, stdout, stderr) {
    var src_path;
    if (socket != null) {
      socket.emit(events.stdout.id, stdout);
      socket.emit(events.stderr.id, stderr);
    }
    if (error != null) {
      next(new ServerError(405, "Could not list the mount the USB drive: " + error));
      return;
    }
    // list the files
    src_path = '/mnt';
    return Fs.readdir(src_path, function(error, files) {
      var f, file, file_stats, i, j, len, len1, ref, scripts;
      if (error != null) {
        next(new ServerError(405, "Could not list the files: " + error));
        return;
      }
      scripts = [];
      for (i = 0, len = files.length; i < len; i++) {
        file = files[i];
        file = Path.resolve(src_path, file);
        file_stats = Fs.statSync(file);
        if ((file_stats != null) && file_stats.isDirectory()) {
          ref = Fs.readdirSync(file);
          for (j = 0, len1 = ref.length; j < len1; j++) {
            f = ref[j];
            if (f.indexOf('.sh') !== -1) {
              scripts.push(Path.resolve(file, f));
            }
          }
        } else if (file.indexOf('.sh') !== -1) {
          scripts.push(Path.resolve(src_path, file));
        }
      }
      response.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
      response.setHeader('Pragma', 'no-cache');
      response.setHeader('Expires', '0');
      response.writeHead(200, {
        'Content-Type': 'application/json'
      });
      return response.end("" + (JSON.stringify(scripts)), 'utf8');
    });
  });
});

router.post('/', function(request, response, next) {
  var process, script;
  if (is_updating) {
    next(new ServerError(405, 'Update already in progress'));
    return;
  }
  if (Os.platform() === 'win32' || Os.platform() === 'darwin') {
    next(new ServerError(503, 'This plattform does not support update'));
    return;
  }
  // Validate the script
  if (request.body.script == null) {
    next(new ServerError(422, 'Parameter \'script\' missing'));
    return;
  }
  // run the update script
  is_updating = true;
  script = Path.join(harrogate_base_path, 'update_wallaby.sh');
  process = spawn(script, [request.body.script]);
  process.stdout.on('data', function(data) {
    return socket.emit(events.stdout.id, data.toString('utf8'));
  });
  process.stderr.on('data', function(data) {
    return socket.emit(events.stderr.id, data.toString('utf8'));
  });
  process.on('error', function(data) {
    return socket.emit(events.stderr.id, data.toString('utf8'));
  });
  return process.on('exit', function(code) {
    is_updating = false;
    socket.emit(events.stdout.id, "Script exited with code " + code);
    response.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
    response.setHeader('Pragma', 'no-cache');
    response.setHeader('Expires', '0');
    response.writeHead(204, {
      'Content-Type': 'application/json'
    });
    return response.end;
  });
});

module.exports = {
  init: function(app) {
    app.web_api.update['router'] = router;
  },
  event_init: function(event_group_name, namespace) {
    namespace.on('connection', update_on_connection);
  },
  exec: function() {}
};

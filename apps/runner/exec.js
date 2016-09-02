var AppCatalog, Config, Directory, Express, HostFileSystem, Path, RunningProgram, ServerError, TargetApp, Workspace, client, events, namespace, router, runner_on_connection, running, running_process, spawn, start_program, stop_program;

Express = require('express');

Path = require('path');

spawn = require('child_process').spawn;

ServerError = require_harrogate_module('/shared/scripts/server-error.js');

AppCatalog = require_harrogate_module('/shared/scripts/app-catalog.js');

Config = require_harrogate_module('config.js');

Directory = require(AppCatalog.catalog['Host Filesystem'].path + '/directory.js');

HostFileSystem = require(AppCatalog.catalog['Host Filesystem'].path + '/host-fs.js');

TargetApp = AppCatalog.catalog['Target information'].get_instance();

Workspace = require(AppCatalog.catalog['Programs'].path + '/workspace.js');

events = AppCatalog.catalog['Runner'].event_groups.runner_events.events;

// information about the program which is currently running
RunningProgram = (function() {
  function RunningProgram(resource) {
    this.resource = resource;
  }

  return RunningProgram;

})();

running = null;

running_process = null;

namespace = null;

client = null;

start_program = function() {
  if ((running != null ? running.resource : void 0) != null) {
    // TODO: change me!!
    // Create data directory
    running.resource.data_directory.create()["finally"](function() {
      var env;
      namespace.emit(events.starting.id, running.resource.name);
      env = Object.create(process.env);
      env.PYTHONPATH = "/usr/lib";
      running_process = spawn(running.resource.binary.path, [], {
        cwd: Path.resolve(running.resource.data_directory.path),
        env: env
      });
      running_process.on('error', function(data) {
        console.log("Could not spawn " + running.resource.binary.path + "!! Error details: " + (JSON.stringify({
          error: data
        })));
        namespace.emit(events.stderr.id, "Program crashed!\n\nError details:\n" + (JSON.stringify({
          error: data
        }, null, '\t')));
        namespace.emit(events.ended.id);
        stop_program();
      });
      running_process.stdout.on('data', function(data) {
        namespace.emit(events.stdout.id, data.toString('utf8'));
      });
      running_process.stderr.on('data', function(data) {
        namespace.emit(events.stderr.id, data.toString('utf8'));
      });
      return running_process.on('exit', function(code) {
        namespace.emit(events.stdout.id, "Program exited with code " + code);
        namespace.emit(events.ended.id);
        stop_program();
      });
    });
  }
};

stop_program = function() {
  if (running_process != null) {
    running_process.kill('SIGINT');
    running_process = null;
  }
  if (running != null) {
    return running = null;
  }
};

// the runner router
router = Express.Router();

// get information about the currently running program
router.get('/current', function(request, response, next) {
  response.writeHead(200, {
    'Content-Type': 'application/json'
  });
  return response.end("" + (JSON.stringify({
    running: running
  })), 'utf8');
});

// get information about the currently running program
router.post('/', function(request, response, next) {
  var ws_resource;
  // Validate the project name
  if (request.body.name == null) {
    response.writeHead(422, {
      'Content-Type': 'application/json'
    });
    return response.end("" + (JSON.stringify({
      error: 'Parameter \'name\' missing'
    })), 'utf8');
  }

  if (request.body.user == null) {
    response.writeHead(422, {
      'Content-Type': 'application/json'
    });
    return response.end("" + (JSON.stringify({
      error: 'Parameter \'user\' missing'
    })), 'utf8');
  }


  ws_resource = null;

  // Create the ws resource
  HostFileSystem.open(request.logged_in_user.preferences.workspace.path).then(function(ws_directory) {
    // return 400 if it is a file
    if (!(ws_directory instanceof Directory)) {
      throw new ServerError(400, ws_directory.path + ' is a file');
    }
    ws_resource = new Workspace(ws_directory);
    // validate it
    return ws_resource.is_valid();
  }).then(function(valid) {
    if (!valid) {
      throw new ServerError(400, ws_resource.ws_directory.path + ' is not a valid workspace');
    }
    // and attach it to the request object
    return ws_resource.get_projects(request.body.user);
  }).then(function(project_resources) {
    var project_resource;
    // search for project.name is request.params.project
    project_resource = ((function() {
      var i, len, results;
      results = [];
      for (i = 0, len = project_resources.length; i < len; i++) {
        project_resource = project_resources[i];
        if (project_resource.name === request.body.name) {
          results.push(project_resource);
        }
      }
      return results;
    })())[0];

    // did we find a project?
    if (project_resource == null) {
      throw new ServerError(404, 'Project ' + request.body.name + ' does not exists');
    } else {
      if (running != null) {
        throw new ServerError(409, request.body.name + ' is already running');
      }
      running = new RunningProgram(project_resource);
      start_program();
      response.writeHead(201, {
        'Content-Type': 'application/json'
      });
      return response.end("" + (JSON.stringify({
        running: running
      })), 'utf8');
    }
  })["catch"](function(e) {
    if (e instanceof ServerError) {
      response.writeHead(e.code, {
        'Content-Type': 'application/javascript'
      });
      return response.end("" + (JSON.stringify({
        error: e.message
      })), 'utf8');
    } else {
      return next(e);
    }
  }).done();
});


// stop the currently running program
router["delete"]('/current', function(request, response, next) {
  stop_program();
  response.writeHead(200, {
    'Content-Type': 'application/json'
  });
  return response.end("" + (JSON.stringify({
    running: running
  })), 'utf8');
});

runner_on_connection = function(socket) {
  return socket.on(events.stdin.id, function(data) {
    if (running_process != null) {
      running_process.stdin.write(data + '\n');
    }
  });
};

module.exports = {
  event_init: function(event_group_name, ns) {
    namespace = ns;
    namespace.on('connection', runner_on_connection);
  },
  init: (function(_this) {
    return function(app) {
      // add the router
      app.web_api.run['router'] = router;
    };
  })(this),
  exec: function() {}
};

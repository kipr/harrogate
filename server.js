var AppCatalog, BodyParser, Config, CookieParser, Express, Http, LocalStrategy, Mkdirp, ON_DEATH, Os, Passport, Path, ServerError, Session, SettingsManager, TargetApp, User, UserManager, api, app, app_name, check_authenticated, event_group, event_group_name, harrogate_app, init_workspace, io, ref, ref1, ref2, ref3, server;

BodyParser = require('body-parser');

CookieParser = require('cookie-parser');

Express = require('express');

Http = require('http');

LocalStrategy = require('passport-local').Strategy;

Mkdirp = require('mkdirp');

ON_DEATH = require('death');

Os = require('os');

Passport = require('passport');

Path = require('path');

Session = require('express-session');

Config = require('./config.js');

if (Os.platform() === 'win32') {
  process.env.PATH += Path.delimiter + ("" + Config.ext_deps.bin_path);
} else if (Os.platform() === 'darwin') {
  process.env.DYLD_LIBRARY_PATH += Path.delimiter + ("" + Config.ext_deps.lib_path);
} else {
  process.env.LD_LIBRARY_PATH += Path.delimiter + ("" + Config.ext_deps.lib_path);
}

if (global.require_harrogate_module == null) {
  global.require_harrogate_module = function(module) {
    return require(__dirname + '/' + module);
  };
}

if (global.harrogate_base_path == null) {
  global.harrogate_base_path = __dirname;
}

AppCatalog = require_harrogate_module('/shared/scripts/app-catalog.js');

SettingsManager = require_harrogate_module('/shared/scripts/settings-manager.js');

ServerError = require_harrogate_module('/shared/scripts/server-error.js');

TargetApp = AppCatalog.catalog['Target information'].get_instance();

User = require_harrogate_module('/shared/scripts/user.js');

UserManager = require_harrogate_module('/shared/scripts/user-manager.js');

init_workspace = function(workspace_path) {
  Mkdirp.sync(workspace_path);
  Mkdirp.sync(Path.join(workspace_path, 'bin'));
  Mkdirp.sync(Path.join(workspace_path, 'data'));
  Mkdirp.sync(Path.join(workspace_path, 'include'));
  Mkdirp.sync(Path.join(workspace_path, 'lib'));
  return Mkdirp.sync(Path.join(workspace_path, 'src'));
};

harrogate_app = Express();

harrogate_app.use(CookieParser());

harrogate_app.use(BodyParser.json({
  limit: '5mb'
}));

harrogate_app.use(Session({
  secret: 'B on harrogate',
  resave: false,
  saveUninitialized: true
}));

harrogate_app.use(Passport.initialize());

harrogate_app.use(Passport.session());

server = Http.createServer(harrogate_app);

io = require('socket.io')(server);

Passport.serializeUser(function(user, done) {
  done(null, user);
});

Passport.deserializeUser(function(user, done) {
  done(null, user);
});

Passport.use(new LocalStrategy(function(username, password, done) {
  if (username == null) {
    return done(null, false);
  }
  if (password === 'test') {
    if (UserManager.users[username] == null) {
      UserManager.add_user(new User(username));
    }
    return done(null, username);
  } else {
    return done(null, false);
  }
}));

check_authenticated = function(request, response, next) {
  if (UserManager.users['User'] == null) {
    UserManager.add_user(new User('User'));
  }
  init_workspace(UserManager.users['User'].preferences.workspace.path);
  request.logged_in_user = UserManager.users['User'];
  return next();
  if (request.isAuthenticated()) {
    if (UserManager.users[request.user] != null) {
      request.logged_in_user = UserManager.users[request.user];
    } else {
      console.log("Unexpected user: " + request.user);
    }
    return next();
  } else {
    response.writeHead(401, {
      'Content-Type': 'application/json'
    });
    response.end("" + (JSON.stringify({
      error: 'Authentication required'
    })), 'utf8');
  }
};

harrogate_app.post('/login', Passport.authenticate('local'), function(request, response, next) {
  response.writeHead(204);
  return response.end();
});

harrogate_app.post('/logout', function(request, response, next) {
  request.logout();
  response.writeHead(204);
  return response.end();
});

harrogate_app.use('/api', check_authenticated, function(request, response, next) {
  return next();
});

harrogate_app.get('/apps/catalog.json', function(request, response, next) {
  return AppCatalog.handle(request, response);
});

ref = AppCatalog.catalog;
for (app_name in ref) {
  app = ref[app_name];
  if (app.get_instance()['init'] != null) {
    console.log("Init " + app_name);
    app.get_instance().init(app);
  }
}

ref1 = AppCatalog.catalog;
for (app_name in ref1) {
  app = ref1[app_name];
  if (app.event_groups != null) {
    for (event_group_name in app.event_groups) {
      event_group = app.event_groups[event_group_name];
      if ((event_group.namespace != null) && (app.get_instance().event_init != null)) {
        console.log("Add Event Namespace: " + event_group.namespace + " --> " + app_name);
        app.get_instance().event_init(event_group_name, io.of(event_group.namespace));
      } else {
        console.warn("Warning: App " + app_name + " has malformed event definitions");
      }
    }
  }
}

ref2 = AppCatalog.catalog;
for (app_name in ref2) {
  app = ref2[app_name];
  if (app.web_api != null) {
    for (api in app.web_api) {
      if (app.web_api[api].router != null) {
        console.log("Add Route: " + app.web_api[api].uri + " --> " + app_name);
        harrogate_app.use(app.web_api[api].uri, app.web_api[api].router);
      } else {
        console.warn("Warning: App " + app_name + " defines web api '" + api + "' but no router");
      }
    }
  }
}

ref3 = AppCatalog.catalog;
for (app_name in ref3) {
  app = ref3[app_name];
  console.log("Starting " + app_name);
  if (app.get_instance()['exec'] != null) {
    app.get_instance().exec();
  }
}

harrogate_app.use(Express["static"](__dirname + '/public'));

harrogate_app.use(function(error, request, response, next) {
  if (error instanceof SyntaxError) {
    response.writeHead(400, {
      'Content-Type': 'application/json'
    });
    return response.end("" + (JSON.stringify({
      error: 'Malformed syntax, could not parse request'
    })), 'utf8');
  }
  if (error instanceof ServerError) {
    response.writeHead(error.code, {
      'Content-Type': 'application/javascript'
    });
    response.end("" + (JSON.stringify({
      error: error.message
    })), 'utf8');
    return;
  }
  console.error('!!!!INTERNAL SERVER ERROR!!!!');
  console.error(error);
  console.error('Stack Trace:');
  console.error(error.stack);
  response.writeHead(500);
  return response.end();
});

server.listen(SettingsManager.settings.server.port, function() {
  console.log("\n\n\n\n");
  console.log("*************************************************************");
  console.log("KISS IDE Server " + Config.version.major + "." + Config.version.minor + "." + Config.version.build_number + " started");
  console.log("  Open your browser to 127.0.0.1:" + (server.address().port));
  console.log("  Close this terminal to kill the KISS IDE Server");
  return console.log("*************************************************************");
});

ON_DEATH(function(signal, err) {
  var ref4;
  console.log("Stopping express.js server");
  server.close();
  ref4 = AppCatalog.catalog;
  for (app_name in ref4) {
    app = ref4[app_name];
    console.log("Stopping " + app_name);
    if (app.get_instance()['closing']) {
      app.get_instance().closing();
    }
  }
  throw 'exiting';
});

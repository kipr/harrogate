var AppCatalog, AppManifest, Directory, Express, ServerError, Url, UserManager, UserResource, router;

Express = require('express');

Url = require('url');

AppCatalog = require_harrogate_module('/shared/scripts/app-catalog.js');

ServerError = require_harrogate_module('/shared/scripts/server-error.js');

UserManager = require_harrogate_module('/shared/scripts/user-manager.js');

UserResource = require('./rest-resources/user-resource.js');

AppManifest = require('./manifest.json');

Directory = require(AppCatalog.catalog['Host Filesystem'].path + '/directory.js');

// the fs router
router = Express.Router();

// '/' is relative to <manifest>.web_api.user.uri
router.get('/current', function(request, response, next) {
  var user_resource;
  if (request.logged_in_user != null) {
    user_resource = new UserResource(request.logged_in_user);
    return user_resource.get_representation().then(function(representation) {
      response.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
      response.setHeader('Pragma', 'no-cache');
      response.setHeader('Expires', '0');
      response.writeHead(200, {
        'Content-Type': 'application/json'
      });
      return response.end("" + (JSON.stringify(representation)), 'utf8');
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
  } else {
    response.writeHead(404, {
      'Content-Type': 'application/json'
    });
    return response.end("" + (JSON.stringify({
      error: 'No user is logged in'
    })), 'utf8');
  }
});

router.get('/', function(request, response, next) {
  var ref, representation, user, user_name, user_resource;
  representation = {
    links: {
      self: {
        href: AppManifest.web_api.users.uri
      }
    }
  };
  if (request.logged_in_user != null) {
    representation.links.current = {
      login: request.logged_in_user.login,
      href: request.logged_in_user.uri
    };
  }
  ref = UserManager.users;
  for (user_name in ref) {
    user = ref[user_name];
    if (representation.links.users == null) {
      representation.links.users = [];
    }
    user_resource = new UserResource(user);
    representation.links.users.push({
      login: user_resource.user.login,
      href: user_resource.url
    });
  }
  response.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
  response.setHeader('Pragma', 'no-cache');
  response.setHeader('Expires', '0');
  response.writeHead(200, {
    'Content-Type': 'application/json'
  });
  return response.end("" + (JSON.stringify(representation)), 'utf8');
});

router.put('/:user', function(request, response, next) {
  var ref, ref1, ws_dir;

  // We only support application/json
  if (!/application\/json/i.test(request.headers['content-type'])) {
    next(new ServerError(415, 'Only content-type application/json supported'));
    return;
  }

  // did a user with the given name exists
  if (UserManager.users[request.params.user] == null) {
    throw new ServerError(404, 'User ' + request.params.user + ' does not exists');
  }


  // TODO: Make this more generic. Currently one the workspace path is supported

  // Validate the type
  if (((ref = request.body.preferences) != null ? (ref1 = ref.workspace) != null ? ref1.path : void 0 : void 0) == null) {
    response.writeHead(422, {
      'Content-Type': 'application/json'
    });
    return response.end("" + (JSON.stringify({
      error: 'Parameter \'preferences.workspace.path\' missing'
    })), 'utf8');
  }

  // Check if the workspace directory exists
  ws_dir = Directory.create_from_path(request.body.preferences.workspace.path);
  ws_dir.is_valid().then((function(_this) {
    return function(valid) {
      if (!valid) {
        next(new ServerError(404, 'Workspace path is not a valid directory'));
        return;
      }
      UserManager.update_user(request.params.user, request.body);
      response.writeHead(204);
      response.end();
    };
  })(this))["catch"](function(e) {
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

module.exports = {
  init: (function(_this) {
    return function(app) {
      app.web_api.users['router'] = router;
    };
  })(this),
  exec: function() {}
};

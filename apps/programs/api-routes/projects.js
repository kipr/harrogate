var AppCatalog, Directory, Express, Fs, HostFileSystem, Project, Q, ServerError, Tar, Url, Workspace, Zlib, router;

Express = require('express');

Fs = require('fs');

Tar = require('tar-stream');

Zip = require('zip-stream');

Q = require('q');

Url = require('url');

Zlib = require('zlib');

AppCatalog = require_harrogate_module('/shared/scripts/app-catalog.js');

Project = require('../project.js');

ServerError = require_harrogate_module('/shared/scripts/server-error.js');

Workspace = require('../workspace.js');

Directory = require(AppCatalog.catalog['Host Filesystem'].path + '/directory.js');

HostFileSystem = require(AppCatalog.catalog['Host Filesystem'].path + '/host-fs.js');

// the fs router
router = Express.Router();

// '/' is relative to <manifest>.web_api.projects.uri
router.use('/', function(request, response, next) {
  var ws_resource;
  ws_resource = null;

  // Create the ws resource
  HostFileSystem.open(request.logged_in_user.preferences.workspace.path).then(function(ws_directory) {

    // return 400 if it is a file
    if (!(ws_directory instanceof Directory)) {
      throw new ServerError(400, ws_directory.path + ' is a file');
    }
    ws_resource = new Workspace(ws_directory);
    return ws_resource.is_valid();

  }).then(function(valid) {
    // validate it
    if (!valid) {
      throw new ServerError(400, ws_resource.ws_directory.path + ' is not a valid workspace');
    }
    // and attach it to the request object
    request.ws_resource = ws_resource;
    return next();
  })["catch"](function(e) {
    // could not create the ws resource (wrong path)
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

router.get('/', function(request, response, next) {
  request.ws_resource.get_representation().then(function(representation) {
    var callback;
    callback = Url.parse(request.url, true).query['callback'];

    // should we return JSON or JSONP (callback defined)?
    if (callback != null) {
      response.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
      response.setHeader('Pragma', 'no-cache');
      response.setHeader('Expires', '0');
      response.writeHead(200, {
        'Content-Type': 'application/javascript'
      });
      return response.end(callback + "(" + (JSON.stringify(representation)) + ")", 'utf8');
    } else {
      response.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
      response.setHeader('Pragma', 'no-cache');
      response.setHeader('Expires', '0');
      response.writeHead(200, {
        'Content-Type': 'application/json'
      });
      return response.end("" + (JSON.stringify(representation)), 'utf8');
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

router.post('/', function(request, response, next) {

  // We only support application/json
  if (!/application\/json/i.test(request.headers['content-type'])) {
    response.writeHead(415, {
      'Content-Type': 'application/json'
    });
    return response.end("" + (JSON.stringify({
      error: 'Only content-type application/json supported'
    })), 'utf8');
  }

  // Validate the name
  if (request.body.name == null) {
    response.writeHead(422, {
      'Content-Type': 'application/json'
    });
    return response.end("" + (JSON.stringify({
      error: 'Parameter \'name\' missing'
    })), 'utf8');
  }

  // Validate the type
  if (request.body.language == null) {
    response.writeHead(422, {
      'Content-Type': 'application/json'
    });
    return response.end("" + (JSON.stringify({
      error: 'Parameter \'language\' missing'
    })), 'utf8');
  }
  request.ws_resource.create_project(request.body.name, request.body.language, request.body.src_file_name).then(function(resource) {
    response.writeHead(201, {
      'Location': "" + resource.uri
    });
    return response.end();
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

router.get('/:project', function(request, response, next) {
  request.ws_resource.get_projects().then(function(project_resources) {
    var pack, project_resource, response_mode;

    // search for project.name is request.params.project
    project_resource = ((function() {
      var i, len, results;
      results = [];
      for (i = 0, len = project_resources.length; i < len; i++) {
        project_resource = project_resources[i];
        if (project_resource.name === request.params.project) {
          results.push(project_resource);
        }
      }
      return results;
    })())[0];
    // did we find a project?
    if (project_resource == null) {
      throw new ServerError(404, 'Project ' + request.params.project + ' does not exists');
    } else {
      // which mode is requested
      response_mode = Url.parse(request.url, true).query['mode'];

      if ((response_mode != null) && response_mode === 'packed') {
        // reply .tar
        pack = Tar.pack();
        return project_resource.pack(pack).then(function(p) {
          response.setHeader("Content-Type", "application/zip");
          response.setHeader('Content-disposition', 'attachment; filename=' + project_resource.name + '.tar');
          response.writeHead(200);
          pack.pipe(response);
          pack.finalize();
        });
      } else if ((response_mode != null) && response_mode === 'compressed') {
        // reply .tar.gz
        pack = Tar.pack();
        return project_resource.pack(pack).then(function(p) {
          response.setHeader("Content-Type", "application/zip");
          response.setHeader('Content-disposition', 'attachment; filename=' + project_resource.name + '.tar.gz');
          response.writeHead(200);
          pack.pipe(Zlib.createGzip()).pipe(response);
          pack.finalize();
        });
      } else if ((response_mode != null) && response_mode === 'zip') {
        // reply .zip
        pack = new Zip();
        return project_resource.pack(pack).then(function(p) {
          response.setHeader("Content-Type", "application/zip");
          response.setHeader('Content-disposition', 'attachment; filename=' + project_resource.name + '.zip');
          response.writeHead(200);
          pack.pipe(response);
          pack.finalize();
        });
      } else {
        //# reply JSON
        return project_resource.get_representation().then(function(representation) {
          var callback;
          callback = Url.parse(request.url, true).query['callback'];

          // should we return JSON or JSONP (callback defined)?
          if (callback != null) {
            response.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
            response.setHeader('Pragma', 'no-cache');
            response.setHeader('Expires', '0');
            response.writeHead(200, {
              'Content-Type': 'application/javascript'
            });
            return response.end(callback + "(" + (JSON.stringify(representation)) + ")", 'utf8');
          } else {
            response.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
            response.setHeader('Pragma', 'no-cache');
            response.setHeader('Expires', '0');
            response.writeHead(200, {
              'Content-Type': 'application/json'
            });
            return response.end("" + (JSON.stringify(representation)), 'utf8');
          }
        });
      }
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

router["delete"]('/:project', function(request, response, next) {
  request.ws_resource.get_projects().then(function(project_resources) {
    var project_resource;

    // search for project.name is request.params.project
    project_resource = ((function() {
      var i, len, results;
      results = [];
      for (i = 0, len = project_resources.length; i < len; i++) {
        project_resource = project_resources[i];
        if (project_resource.name === request.params.project) {
          results.push(project_resource);
        }
      }
      return results;
    })())[0];

    // did we find a project?
    if (project_resource == null) {
      throw new ServerError(404, 'Project ' + request.params.project + ' does not exists');
    } else {
      return project_resource.remove().then(function() {
        response.writeHead(204);
        response.end();
      });
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

// return unsupported method for anything not handlet yet
router.use('/', function(request, response, next) {
  var err_resp;
  err_resp = {
    error: 'Unable to handle request',
    reason: request.method + ' not allowed'
  };
  response.writeHead(405, {
    'Content-Type': 'application/json'
  });
  return response.end("" + (JSON.stringify(err_resp)), 'utf8');
});

module.exports = router;

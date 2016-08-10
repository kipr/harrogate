var AppCatalog, Directory, Express, HostFileSystem, ServerError, TargetApp, Workspace, compilation_environment, router;

Express = require('express');

ServerError = require_harrogate_module('/shared/scripts/server-error.js');

AppCatalog = require_harrogate_module('/shared/scripts/app-catalog.js');

Directory = require(AppCatalog.catalog['Host Filesystem'].path + '/directory.js');

HostFileSystem = require(AppCatalog.catalog['Host Filesystem'].path + '/host-fs.js');

TargetApp = AppCatalog.catalog['Target information'].get_instance();

Workspace = require(AppCatalog.catalog['Programs'].path + '/workspace.js');

// get the compilation environments
if (TargetApp.platform === TargetApp.supported_platforms.WINDOWS_PC) {
  compilation_environment = require('../compilation-environments/c/mingw.js');
} else {
  compilation_environment = require('../compilation-environments/c/gcc.js');
}

// the compiler router
router = Express.Router();

// get information about the currently running program
router.post('/', function(request, response, next) {
  var project_resource, ws_resource;
  // Validate the project name
  if (request.body.name == null) {
    next(new ServerError(422, 'Parameter \'name\' missing'));
    return;
  }
  ws_resource = null;
  project_resource = null;
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
    return ws_resource.get_projects();
  }).then(function(project_resources) {
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
    }
    // delete the bin folder if it exists
    return ws_resource.bin_directory.get_child(project_resource.name);
  }).then((function(child) {
    // bin folder exists, delete it
    return child.remove();
  }), function() {}).then(function() {
    // create the bin folder
    return ws_resource.bin_directory.create_subdirectory(project_resource.name);
  }).then(function() {
    return project_resource.get_representation(false).then(function(project_details) {
      var language;
      language = project_details.parameters.language;
      if (language.toLowerCase() === 'c') {
        if (TargetApp.platform === TargetApp.supported_platforms.WINDOWS_PC) {
          compilation_environment = require('../compilation-environments/c/mingw.js');
        } else {
          compilation_environment = require('../compilation-environments/c/gcc.js');
        }
      } else if (language.toLowerCase() === 'python') {
        compilation_environment = require('../compilation-environments/python/python.js');
      }
      return compilation_environment.compile(project_resource, function(error, stdout, stderr) {
        var result;
        result = {
          stdout: stdout,
          stderr: stderr,
          error: error
        };
        response.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
        response.setHeader('Pragma', 'no-cache');
        response.setHeader('Expires', '0');
        response.writeHead(200, {
          'Content-Type': 'application/json'
        });
        response.end("" + (JSON.stringify({
          result: result
        })), 'utf8');
      });
    });
  })["catch"](function(error) {
    next(error);
  }).done();
});

// export the router object
module.exports = router;

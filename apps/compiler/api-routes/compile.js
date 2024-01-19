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
  // Validate the project req
  if (!request.body.user) {
    next(new ServerError(422, 'Parameter \'user\' missing'));
    return;
  }
  if (!request.body.name) {
    next(new ServerError(422, 'Parameter \'name\' missing'));
    return;
  }

  // Create the ws resource
  HostFileSystem.open(request.logged_in_user.preferences.workspace.path).then(function(ws_directory) {
    // return 400 if it is a file
    if (!(ws_directory instanceof Directory)) {
      throw new ServerError(400, ws_directory.path + ' is a file');
    }
    var ret = new Workspace(ws_directory);
    if(!ret.is_valid()) throw ret.ws_directory.path + ' is not a valid workspace';
    return ret;
  }).then(function(ws_resource) {
    // and attach it to the request object
    return [ws_resource, ws_resource.get_projects(request.body.user)];
  }, function (reason) {
    throw new ServerError(400, reason);
  }).spread(function(ws_resource, project_resources) {
    // search for project.name is request.params.project
    var project_resource = project_resources.filter(function(project) {
      return project.name === request.body.name;
    })[0];

    // did we find a project?
    if (!project_resource) throw new ServerError(404, 'Project ' + request.body.name + ' does not exists');
    
    // delete the bin folder if it exists
    return [project_resource, project_resource.bin_directory];
  }).spread((function(project_resource, bin_dir) {
    // bin folder exists, delete it
    return bin_dir.remove().then(function () { return [project_resource, bin_dir]; });
  }), function() {}).spread(function(project_resource, bin_dir) {
    // create the bin folder
    return bin_dir.create().then(function () {
      return project_resource;
    });
  }).then(function(project_resource) {
    return project_resource.get_representation(false).then(function(project_details) {
      var language = project_details.parameters.language;
      if (language.toLowerCase() === 'c') {
        if (TargetApp.platform === TargetApp.supported_platforms.WINDOWS_PC) {
          compilation_environment = require('../compilation-environments/c/mingw.js');
        } else {
          compilation_environment = require('../compilation-environments/c/gcc.js');
        }
      } else if (language.toLowerCase() === 'python') {
        compilation_environment = require('../compilation-environments/python/python.js');
      }
      else if (language.toLowerCase() === 'c++') {
        compilation_environment = require('../compilation-environments/c++/g++.js');
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

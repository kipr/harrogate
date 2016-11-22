var Express, SettingsManager, router;

Express = require('express');

WorkspaceManager = require_harrogate_module('/shared/scripts/workspace-manager.js');

// the fs router
router = Express.Router();

router.get('/', function(request, response, next) {
  response.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
  response.setHeader('Pragma', 'no-cache');
  response.setHeader('Expires', '0');
  response.writeHead(200, {
    'Content-Type': 'application/json'
  });
  return response.end("" + (JSON.stringify(WorkspaceManager.workspace_path)), 'utf8');
});

router.put('/', function(request, response, next) {
  // We only support application/json
  if (!/application\/json/i.test(request.headers['content-type'])) {
    next(new ServerError(415, 'Only content-type application/json supported'));
    return;
  }

  WorkspaceManager.update_workspace_path(request.body.path);

  response.writeHead(204);
  response.end();
});

module.exports = router;

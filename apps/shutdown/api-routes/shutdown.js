var Express, Os, exec, router;

exec = require('child_process').exec;

Os = require('os');

Express = require('express');

router = Express.Router();

router.post('/', function(request, response, next) {
  if (Os.platform() === 'win32' || Os.platform() === 'darwin') {
    next(new ServerError(503, 'This plattform does not support update'));
    return;
  }
  exec('poweroff');
  console.log('poweroff called');
  response.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
  response.setHeader('Pragma', 'no-cache');
  response.setHeader('Expires', '0');
  response.writeHead(204, {
    'Content-Type': 'application/json'
  });
  return response.end;
});

module.exports = router;

exec = require('child_process').exec

Os = require 'os'

Express = require 'express'

# the fs router
router = Express.Router()

router.post '/', (request, response, next) ->

  if Os.platform() is 'win32' or Os.platform() is 'darwin'
    next new ServerError(503, 'This plattform does not support update')
    return
    
  exec 'poweroff'
  console.log 'poweroff called'

  response.setHeader 'Cache-Control', 'no-cache, no-store, must-revalidate'
  response.setHeader 'Pragma', 'no-cache'
  response.setHeader 'Expires', '0'
  response.writeHead 204, { 'Content-Type': 'application/json' }
  return response.end

module.exports = router

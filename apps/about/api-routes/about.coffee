Express = require 'express'

# the fs router
router = Express.Router()

Config = require_harrogate_module 'config.coffee'

# '/' is relative to <manifest>.web_api.settings.uri
router.get '/', (request, response, next) ->
  response.setHeader 'Cache-Control', 'no-cache, no-store, must-revalidate'
  response.setHeader 'Pragma', 'no-cache'
  response.setHeader 'Expires', '0'
  response.writeHead 200, { 'Content-Type': 'application/json' }
  return response.end "#{JSON.stringify({config: Config})}", 'utf8'

module.exports = router

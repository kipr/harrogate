Express = require 'express'

SettingsManager = require '../../../shared/scripts/settings-manager.coffee'

# the fs router
router = Express.Router()

# '/' is relative to <manifest>.web_api.settings.uri
router.get '/', (request, response, next) ->
  response.setHeader 'Cache-Control', 'no-cache, no-store, must-revalidate'
  response.setHeader 'Pragma', 'no-cache'
  response.setHeader 'Expires', '0'
  response.writeHead 200, { 'Content-Type': 'application/json' }
  return response.end "#{JSON.stringify(SettingsManager.settings)}", 'utf8'

module.exports = router
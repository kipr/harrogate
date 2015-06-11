Express = require 'express'

SettingsManager = require '../../../shared/scripts/settings-manager.coffee'

# the fs router
router = Express.Router()

# '/' is relative to <manifest>.web_api.settings.uri
router.get '/', (request, response, next) ->
  response.writeHead 200, { 'Content-Type': 'application/json' }
  return response.end "#{JSON.stringify(SettingsManager.settings)}", 'utf8'

module.exports = router
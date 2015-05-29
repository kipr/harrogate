Express = require 'express'
Url = require 'url'

SettingsManager = require '../../shared/scripts/settings-manager'

# the fs router
router = Express.Router()

# '/' is relative to <manifest>.web_api.settings.uri
router.get '/', (request, response, next) ->
  response.writeHead 200, { 'Content-Type': 'application/json' }
  return response.end "#{JSON.stringify(SettingsManager.settings)}", 'utf8'

module.exports =
  init: (app) =>
    # add the router
    app.web_api.settings['router'] = router
    return

  exec: ->
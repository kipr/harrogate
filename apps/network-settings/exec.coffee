module.exports =
  init: (app) =>
    # add the router
    app.web_api.settings['router'] = require './api-routes/network-settings.coffee'
    return

  exec: ->
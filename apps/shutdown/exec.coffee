module.exports =
  init: (app) =>
    # add the router
    app.web_api.shutdown['router'] = require './api-routes/shutdown.coffee'
    return

  exec: ->

module.exports =
  init: (app) =>
    # add the router
    app.web_api.servos['router'] = require './api-routes/servos.coffee'
    return
  exec: ->
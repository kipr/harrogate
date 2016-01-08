module.exports =
  init: (app) =>
    # add the router
    app.web_api.motors['router'] = require './api-routes/motors.coffee'
    return
  exec: ->
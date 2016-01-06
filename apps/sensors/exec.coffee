module.exports =
  init: (app) =>
    # add the router
    app.web_api.sensors['router'] = require './api-routes/sensors.coffee'
    return
  exec: ->
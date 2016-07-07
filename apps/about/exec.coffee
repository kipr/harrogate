module.exports =
  init: (app) =>
    # add the router
    app.web_api.about['router'] = require './api-routes/about.js'
    return

  exec: ->

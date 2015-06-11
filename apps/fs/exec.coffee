module.exports = 
  init: (app) ->
    # add the the router
    app.web_api.fs['router'] = require './api-routes/fs.coffee'

  exec: ->
    return
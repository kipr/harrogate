module.exports =

  init: (app) ->
    app.web_api.run['router'] = require './api-routes/compile.coffee'
    return

  exec: ->
    return

module.exports =
  init: (app) ->
    app.web_api.projects['router'] = require './api-routes/projects.coffee'

  exec: ->
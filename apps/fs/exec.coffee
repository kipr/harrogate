class FsApp
  constructor: ->

  init: (app) =>
    # add the the router
    app.web_api.fs['router'] = require './api-router/fs.coffee'

  exec: ->

# export the app object
module.exports = new FsApp
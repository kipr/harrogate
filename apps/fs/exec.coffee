Directory = require './directory.coffee'
SettingsManager = require '../../shared/scripts/settings-manager'

class FsApp
  constructor: ->
    @home_directory = Directory.create_from_path SettingsManager.settings.workspace.path

  init: (app) =>
    # add the home directory and the router
    app.web_api.fs['home_uri'] = @home_directory.uri
    app.web_api.fs['router'] = require './api-router/fs.coffee'

  exec: ->

# export the app object
module.exports = new FsApp
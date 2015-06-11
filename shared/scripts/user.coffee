Path = require 'path'

AppCatalog = require '../../shared/scripts/app-catalog.coffee'
TargetApp = AppCatalog.catalog['Target information'].get_instance()

class User
  constructor: (@login) ->
    @preferences = {}

    # set default workspace
    @preferences.workspace = {}
    if TargetApp.platform is TargetApp.supported_platforms.WINDOWS_PC
       @preferences.workspace.path = Path.join process.env['USERPROFILE'], 'Documents', 'KISS'
    else
       @preferences.workspace.path = Path.join process.env['HOME'], 'Documents', 'KISS'
    

module.exports = User
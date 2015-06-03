fs = require 'fs'
path = require 'path'
_ = require 'lodash'

AppCatalog = require '../../shared/scripts/app-catalog.coffee'
TargetApp = AppCatalog.catalog['Target information'].get_instance()

class SettingsManager
  constructor: ->
    @settings_file_paht = path.join process.cwd(), 'settings.json'

    @settings = require @settings_file_paht

  update: (value) =>
    console.log @settings
    @settings =  _.merge(@settings, value)
    console.log @settings
    fs.writeFile @settings_file_paht, JSON.stringify(@settings, null, 2), 'utf8'
    return

  set: (value) =>
    @settings =  Object.freeze value
    fs.writeFile @settings_file_paht, JSON.stringify(@settings, null, 2), 'utf8'
    return

  reset_to_platform_default: =>
    settings = {}

    # Server settings
    settings.server =
      port: 8888

    # Workspace settings
    settings.workspace = {}

    if TargetApp.platform is TargetApp.supported_platforms.WINDOWS_PC
      settings.workspace.path = path.join process.env['USERPROFILE'], 'Documents', 'KISS'
    else
      settings.workspace.path = path.join process.env['HOME'], 'Documents', 'KISS'

    @set settings
    return

module.exports = new SettingsManager
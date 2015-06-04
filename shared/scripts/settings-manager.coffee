fs = require 'fs'
path = require 'path'
_ = require 'lodash'

class SettingsManager
  constructor: ->
    @settings_file_paht = path.join process.cwd(), 'settings.json'

    @settings = require @settings_file_paht

  update: (value) =>
    @settings =  _.merge(@settings, value)
    fs.writeFile @settings_file_paht, JSON.stringify(@settings, null, 2), 'utf8'
    return

  set: (value) =>
    @settings =  value
    fs.writeFile @settings_file_paht, JSON.stringify(@settings, null, 2), 'utf8'
    return

  reset_to_platform_default: =>
    settings = {}

    # Server settings
    settings.server =
      port: 8888

    @set settings
    return

module.exports = new SettingsManager
fs = require 'fs'
path = require 'path'
_ = require 'lodash'

class SettingsManager
  constructor: ->
    @settings_file_paht = path.join process.cwd(), 'settings.json'

    @settings = Object.freeze require(@settings_file_paht)

  set: (value) =>
    @settings =  Object.freeze _.merge(@settings, value)
    fs.writeFile @settings_file_paht, JSON.stringify(@settings, null, 2), 'utf8'
    return

module.exports = new SettingsManager
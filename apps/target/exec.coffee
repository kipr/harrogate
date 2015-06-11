Os = require 'os'

class TargetInformation
  constructor: ->
    @supported_platforms =
      LINK: 0
      LINK2: 1
      WINDOWS_PC: 2
      MAC: 3
    @platform = undefined

    @supported_os =
      LINUX: 0
      WINDOWS: 1
      OSX: 2
    @os = undefined

    switch Os.platform()
      when 'win32'
        @platform = @supported_platforms.WINDOWS_PC
        @os = @supported_os.WINDOWS
      when 'darwin'
        @platform = @supported_platforms.MAC
        @os = @supported_os.OSX
      # TODO: Add info for Link?/Link2

  init: (app) ->
    # Add the target information
    app['supported_platforms'] = @supported_platforms
    app['platform'] = @platform

    app['supported_os'] = @supported_os
    app['os'] = @os
    return

module.exports = new TargetInformation

io = require 'socket.io-client'

exports.name = 'camera_view_controller'

exports.inject = (app) ->
  app.controller exports.name,
    [
      '$scope'
      'app_catalog_provider'
      exports.controller
    ]
  exports.controller

exports.controller = ($scope, app_catalog_provider) ->
  app_catalog_provider.catalog.then (app_catalog) ->
    camera_event_group =  app_catalog['Camera']?.event_groups?.camera_events
    if camera_event_group?
      socket = io ':8888' + camera_event_group.namespace

      socket.on camera_event_group.events.frame_arrived.id, (msg) ->
        $('#camera').attr 'src', "data:image/jpeg;base64,#{msg}"
        return
    return
  return 
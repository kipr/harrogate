Io = require 'socket.io-client'

exports.name = 'CameraViewController'

exports.inject = (app) ->
  app.controller exports.name, [
      '$scope'
      'AppCatalogProvider'
      exports.controller
    ]
  return

exports.controller = ($scope, AppCatalogProvider) ->

  AppCatalogProvider.catalog.then (app_catalog) ->
    camera_event_group =  app_catalog['Camera']?.event_groups?.camera_events
    if camera_event_group?
      socket = Io ':8888' + camera_event_group.namespace

      socket.on camera_event_group.events.frame_arrived.id, (msg) ->

        $scope.$apply ->
          $scope.img_src = "data:image/jpeg;base64,#{msg}"
          return

        return

    return

  return 
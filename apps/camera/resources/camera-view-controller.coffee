CodeMirror = require 'codemirror/lib/codemirror'
Io = require 'socket.io-client'

exports.name = 'CameraViewController'

exports.inject = (app) ->
  app.controller exports.name, [
    '$scope'
    '$http'
    '$location'
    '$timeout'
    'AppCatalogProvider'
    exports.controller
  ]
  return

exports.controller = ($scope, $http, $location, $timeout, AppCatalogProvider) ->

  socket = undefined
  events = undefined
  img_width = undefined
  img_height = undefined

  AppCatalogProvider.catalog.then (app_catalog) ->
    events =  app_catalog['Camera']?.event_groups?.camera_events.events
    events_namespace =  app_catalog['Camera']?.event_groups?.camera_events.namespace
    if events?
      socket = Io ':8888' + events_namespace

      socket.on events.frame_arrived.id, (msg) ->
        img_width = msg.width
        img_height = msg.height

        $scope.$apply ->
          $scope.img_src = '/api/camera?' + new Date().getTime()
          return

       return

    return

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
    camera_wss_port = app_catalog['Camera']?.config?.camera_wss_port
    if camera_wss_port?
      socket = new WebSocket("ws://#{location.hostname}:#{camera_wss_port}")

      socket.onmessage = (m) ->
        $('#camera').attr 'src', "data:image/jpeg;base64,#{m.data}"
        return

      # close socket if we leave the view
      $scope.$on '$locationChangeStart', (e) ->
        socket.close()
        return
    return
  return 
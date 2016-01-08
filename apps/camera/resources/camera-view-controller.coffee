exports.name = 'CameraViewController'

exports.inject = (app) ->
  app.controller exports.name, [
    '$scope'
    'frame_data'
    exports.controller
  ]
  app.factory 'frame_data', ($websocket) ->
    dataStream = $websocket('ws://localhost:8889/camera_frame_data')
    collection = []
    dataStream.onMessage (msg) -> collection.push JSON.parse(msg.data)
    methods =
      collection: collection
      get: -> dataStream.send JSON.stringify(action: 'get')
  return

exports.controller = ($scope, frame_data) ->
  $scope.frame_data = frame_data
  $scope.show_visual = true
  $scope.selected_channel = false

exports.name = 'CameraViewController'

exports.inject = (app) ->
  app.controller exports.name, [
    '$scope'
    exports.controller
  ]
  return

exports.controller = ($scope) ->

  $scope.show_visual = true
  $scope.selected_channel = false

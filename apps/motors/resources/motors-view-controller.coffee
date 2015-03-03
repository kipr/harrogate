exports.name = 'motors_view_controller'

exports.inject = (app) ->
  app.controller exports.name,
    [
      '$scope'
      exports.controller
    ]
  exports.controller

exports.controller = ($scope) ->
  $scope.test = 'Hello from motors-view-controller.coffee'
  return
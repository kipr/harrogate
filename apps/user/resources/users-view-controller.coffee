exports.name = 'users_view_controller'

exports.inject = (app) ->
  app.controller exports.name, [
    '$scope'
    'user_manager_service'
    exports.controller
  ]
  exports.controller

exports.controller = ($scope, user_manager_service) ->

  $scope.login = ->
    user_manager_service.login $scope.username, $scope.password
    return
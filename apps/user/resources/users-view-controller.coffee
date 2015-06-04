exports.name = 'users_view_controller'

exports.inject = (app) ->
  app.controller exports.name, [
    '$scope'
    'user_manager_service'
    exports.controller
  ]
  exports.controller

exports.controller = ($scope, user_manager_service) ->
  get_current_user = ->
    user_manager_service.get_current_user().then (current_user) ->
      $scope.current_user = current_user
      return

  get_current_user()

  $scope.logout = ->
    user_manager_service.logout()
    .then ->
      $scope.current_user = null
      return
    return

  $scope.login = ->
    user_manager_service.login($scope.username, $scope.password)
    .then ->
      get_current_user()
      return
    return
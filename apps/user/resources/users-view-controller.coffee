exports.name = 'UsersViewController'

exports.inject = (app) ->
  app.controller exports.name, [
    '$scope'
    'UserManagerService'
    exports.controller
  ]
  return

exports.controller = ($scope, UserManagerService) ->
  get_current_user = ->
    UserManagerService.get_current_user().then (current_user) ->
      $scope.current_user = current_user
      return

  get_current_user()

  $scope.logout = ->
    UserManagerService.logout()
    .then ->
      $scope.current_user = null
      return
    return

  $scope.login = ->
    UserManagerService.login($scope.username, $scope.password)
    .then ->
      get_current_user()
      return
    return
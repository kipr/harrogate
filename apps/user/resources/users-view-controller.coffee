exports.name = 'UsersViewController'

exports.inject = (app) ->
  app.controller exports.name, [
    '$scope'
    'UserManagerService'
    'ButtonsOnlyModalFactory'
    exports.controller
  ]
  return

exports.controller = ($scope, UserManagerService, ButtonsOnlyModalFactory) ->
  get_current_user = ->
    UserManagerService.get_current_user().then (current_user) ->
      $scope.current_user = current_user
      return

  get_current_user()

  $scope.apply_change = ->
    UserManagerService.change_workspace_path($scope.current_user.login,
                                             $scope.current_user.preferences.workspace.path)
    .then (->
      ButtonsOnlyModalFactory.open(
        'Workspace path changed'
        'Your workspace path was changed to ' + $scope.current_user.preferences.workspace.path
        [ 'Ok' ])

    ), (status) ->
      if status is 404
        ButtonsOnlyModalFactory.open(
          'Could not change workspace path'
          'Could not change workspace path to ' + $scope.current_user.preferences.workspace.path +
            ', directory does not exist'
          [ 'Ok' ])
      else
        ButtonsOnlyModalFactory.open(
          'Could not change workspace path'
          'Could not change workspace path to ' + $scope.current_user.preferences.workspace.path
          [ 'Ok' ])
      get_current_user()

  $scope.reset = ->
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
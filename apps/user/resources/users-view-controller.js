exports.name = 'UsersViewController';

exports.inject = function(app) {
  app.controller(exports.name, ['$scope', 'UserManagerService', 'ButtonsOnlyModalFactory', exports.controller]);
};

exports.controller = function($scope, UserManagerService, ButtonsOnlyModalFactory) {
  var get_current_user;
  get_current_user = function() {
    return UserManagerService.get_current_user().then(function(current_user) {
      $scope.current_user = current_user;
    });
  };
  get_current_user();
  $scope.apply_change = function() {
    return UserManagerService.change_workspace_path($scope.current_user.login, $scope.current_user.preferences.workspace.path).then((function() {
      return ButtonsOnlyModalFactory.open('Workspace path changed', 'Your workspace path was changed to ' + $scope.current_user.preferences.workspace.path, ['Ok']);
    }), function(status) {
      if (status === 404) {
        ButtonsOnlyModalFactory.open('Could not change workspace path', 'Could not change workspace path to ' + $scope.current_user.preferences.workspace.path + ', directory does not exist', ['Ok']);
      } else {
        ButtonsOnlyModalFactory.open('Could not change workspace path', 'Could not change workspace path to ' + $scope.current_user.preferences.workspace.path, ['Ok']);
      }
      return get_current_user();
    });
  };
  $scope.reset = function() {
    return get_current_user();
  };
  $scope.logout = function() {
    UserManagerService.logout().then(function() {
      $scope.current_user = null;
    });
  };
  return $scope.login = function() {
    UserManagerService.login($scope.username, $scope.password).then(function() {
      get_current_user();
    });
  };
};

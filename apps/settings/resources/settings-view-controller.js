exports.name = 'SettingsViewController';

exports.inject = function(app) {
  app.controller(exports.name, ['$scope', '$http', 'WorkspaceManagerService', 'AppCatalogProvider', 'ButtonsOnlyModalFactory', exports.controller]);
};

exports.controller = function($scope, $http, WorkspaceManagerService, AppCatalogProvider, ButtonsOnlyModalFactory) {
  AppCatalogProvider.catalog.then(function(app_catalog) {
    var ref, ref1, settings_api;
    settings_api = (ref = app_catalog['Settings']) != null ? (ref1 = ref.web_api) != null ? ref1.settings : void 0 : void 0;
    if (settings_api != null) {
      $http.get(settings_api.uri).success(function(data, status, headers, config) {
        $scope.settings = data;
      });
    }
  });
  WorkspaceManagerService.get_workspace_path().then(function(path) {
    $scope.workspace_path = path;
    $scope.original_workspace_path = path;
  }, function(status) {
    // ERROR
    console.log(status);
  });
  
  $scope.apply_change = function() {
    return WorkspaceManagerService.change_workspace_path($scope.workspace_path).then((function() {
      $scope.original_workspace_path = $scope.workspace_path;
      return ButtonsOnlyModalFactory.open('Workspace path changed', 'Your workspace path was changed to ' + $scope.workspace_path, ['Ok']);
    }), function(status) {
      if (status === 404) {
        ButtonsOnlyModalFactory.open('Could not change workspace path', 'Could not change workspace path to ' + $scope.workspace_path + ', directory does not exist', ['Ok']);
      } else {
        ButtonsOnlyModalFactory.open('Could not change workspace path', 'Could not change workspace path to ' + $scope.workspace_path, ['Ok']);
      }
    });
  };
  $scope.reset = function() {
    $scope.workspace_path = $scope.original_workspace_path;
  };
};

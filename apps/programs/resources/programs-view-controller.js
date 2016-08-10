exports.name = 'ProgramsViewController';

exports.inject = function(app) {
  app.controller(exports.name, ['$scope', '$http', 'AppCatalogProvider', exports.controller]);
};

exports.controller = function($scope, $http, AppCatalogProvider) {
  AppCatalogProvider.catalog.then(function(app_catalog) {
    var fs_api, ref, ref1;
    fs_api = (ref = app_catalog['Programs']) != null ? (ref1 = ref.web_api) != null ? ref1.projects : void 0 : void 0;
    if (fs_api != null) {
      $http.get(fs_api.uri).success(function(data, status, headers, config) {
        $scope.ws = data;
      });
    }
  });
  $scope.select_project = function(project) {
    $scope.selected = project;
  };
};

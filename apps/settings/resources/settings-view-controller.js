exports.name = 'SettingsViewController';

exports.inject = function(app) {
  app.controller(exports.name, ['$scope', '$http', 'AppCatalogProvider', exports.controller]);
};

exports.controller = function($scope, $http, AppCatalogProvider) {
  AppCatalogProvider.catalog.then(function(app_catalog) {
    var ref, ref1, settings_api;
    settings_api = (ref = app_catalog['Settings']) != null ? (ref1 = ref.web_api) != null ? ref1.settings : void 0 : void 0;
    if (settings_api != null) {
      $http.get(settings_api.uri).success(function(data, status, headers, config) {
        $scope.settings = data;
      });
    }
  });
};

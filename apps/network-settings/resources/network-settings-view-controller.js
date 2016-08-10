exports.name = 'NetworkSettingsViewController';

exports.inject = function(app) {
  app.controller(exports.name, ['$scope', '$http', 'AppCatalogProvider', exports.controller]);
};

exports.controller = function($scope, $http, AppCatalogProvider) {
  $scope.show_wifi = true;
  return AppCatalogProvider.catalog.then(function(app_catalog) {
    var ref, ref1, settings_api;
    return settings_api = (ref = app_catalog['Network-Settings']) != null ? (ref1 = ref.web_api) != null ? ref1.settings : void 0 : void 0;
  });
};

exports.name = 'AboutViewController';

exports.inject = function(app) {
  app.controller(exports.name, ['$scope', '$http', 'AppCatalogProvider', exports.controller]);
};

exports.controller = function($scope, $http, AppCatalogProvider) {
  return AppCatalogProvider.catalog.then(function(app_catalog) {
    var about_api, ref, ref1;
    about_api = (ref = app_catalog['About']) != null ? (ref1 = ref.web_api) != null ? ref1.about : void 0 : void 0;
    if (about_api != null) {
      return $http.get(about_api.uri).success(function(data, status, headers, config) {
        return $scope.about = data;
      });
    }
  });
};

exports.name = 'UsersViewController';

exports.inject = function(app) {
  app.controller(exports.name, ['$scope', '$http', 'AppCatalogProvider', 'ButtonsOnlyModalFactory', exports.controller]);
};

exports.controller = function($scope, $http, AppCatalogProvider, ButtonsOnlyModalFactory) {
  AppCatalogProvider.catalog.then(function(app_catalog) {
    var projects_resource, ref, ref1;
    projects_resource = (ref = app_catalog['Programs']) != null ? (ref1 = ref.web_api) != null ? ref1.projects : void 0 : void 0;
    $scope.users_uri = projects_resource.uri + '/users';
    $scope.update_users();
  });
  sort_users = function(users) {
    users.sort(function(a, b) {
      const nameA = a.name.toUpperCase();
      const nameB = b.name.toUpperCase();

      if (nameA === "DEFAULT USER") return -1;
      if (nameB === "DEFAULT USER") return 1;

      if (nameA < nameB) return -1;
      if (nameA > nameB) return 1;

      return 0;
    });

    return users;
  }
  $scope.update_users = function() {
    $http.get($scope.users_uri).success(function(data, status, headers, config) {
      $scope.users = Object.keys(data).map(function(user, i) { return {id: i, name: user, data: data[user]}; });
      $scope.users = sort_users($scope.users);
      $scope.active_user = $scope.users[0];
    });
  }

  $scope.active_user_changed = function() {

  }

  $scope.modes = ['Simple', 'Advanced'];

  $scope.mode_changed = function() {
    $http.put($scope.users_uri + '/' + $scope.active_user.name, $scope.active_user.data).then(function() {
    }, function(data, status) {
      console.log("ERROR!! ", data, status);
    })
  }
};

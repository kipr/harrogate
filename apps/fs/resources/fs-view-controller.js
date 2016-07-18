exports.name = 'FsViewController';

exports.inject = function(app) {
  app.controller(exports.name, ['$scope', '$http', 'AppCatalogProvider', 'UserManagerService', exports.controller]);
};

exports.controller = function($scope, $http, AppCatalogProvider, UserManagerService) {
  var open_dir, root_dir_uri;
  open_dir = function(uri) {
    $scope.current = void 0;
    $scope.selected = void 0;
    $http.get(uri).success(function(data, status, headers, config) {
      $scope.current = data;
    });
  };
  root_dir_uri = void 0;
  AppCatalogProvider.catalog.then(function(app_catalog) {
    var fs_api, ref, ref1;
    fs_api = (ref = app_catalog['Host Filesystem']) != null ? (ref1 = ref.web_api) != null ? ref1.fs : void 0 : void 0;
    if (fs_api != null) {
      open_dir(fs_api.uri);
      root_dir_uri = fs_api.uri;
    }
  });
  UserManagerService.get_current_user().then(function(current_user) {
    var ref, ref1, ref2, ref3;
    $scope.home_uri = current_user != null ? (ref = current_user.preferences) != null ? (ref1 = ref.workspace) != null ? (ref2 = ref1.links) != null ? (ref3 = ref2.self) != null ? ref3.href : void 0 : void 0 : void 0 : void 0 : void 0;
  });
  $scope.open_directory = function(directory) {
    open_dir(directory.links.self.href);
  };
  $scope.can_up = function() {
    return $scope.current && $scope.current.links.self.href !== root_dir_uri;
  };
  $scope.select_child = function(child) {
    if ($scope.selected === child && child.type === 'Directory') {
      $scope.open_directory(child);
    } else {
      $scope.selected = child;
    }
  };
  $scope.home = function() {
    if ($scope.home_uri != null) {
      open_dir($scope.home_uri);
    }
  };
  $scope.root = function() {
    if (root_dir_uri != null) {
      open_dir(root_dir_uri);
    }
  };
  $scope.up = function() {
    if ($scope.current.parent != null) {
      open_dir($scope.current.parent.links.self.href);
    }
  };
  $scope.reload = function() {
    open_dir($scope.current.links.self.href);
  };
};
RunLink

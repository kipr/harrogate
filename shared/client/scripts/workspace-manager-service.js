exports.name = 'WorkspaceManagerService';

exports.inject = function(app) {
  app.service(exports.name, ['$http', '$q', '$location', 'authRequiredInterceptor', 'ButtonsOnlyModalFactory', exports.service]);
  return exports.service;
};

exports.service = function($http, $q, $location, authRequiredInterceptor, ButtonsOnlyModalFactory) {
  var WorkspaceManagerService, workspace_api_uri;
  workspace_api_uri = '/api/workspace';
  WorkspaceManagerService = (function() {
    function WorkspaceManagerService() {}

    WorkspaceManagerService.prototype.get_workspace_path = function() {
      return $q(function(resolve, reject) {
        return $http.get(workspace_api_uri).success(function(data, status) {
          return resolve(data);
        }).error(function(data, status) {
          return reject(status);
        });
      });
    };

    WorkspaceManagerService.prototype.change_workspace_path = function(path) {
      return $q(function(resolve, reject) {
        return $http.patch(workspace_api_uri, {
          path: path
        }).success(function() {
          return resolve();
        }).error(function(data, status) {
          return reject(status);
        });
      });
    };

    return WorkspaceManagerService;
  })();

  return new WorkspaceManagerService;
};

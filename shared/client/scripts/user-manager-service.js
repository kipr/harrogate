exports.name = 'UserManagerService';

exports.inject = function(app) {
  app.service(exports.name, ['$http', '$q', '$location', 'authRequiredInterceptor', 'ButtonsOnlyModalFactory', exports.service]);
  return exports.service;
};

exports.service = function($http, $q, $location, authRequiredInterceptor, ButtonsOnlyModalFactory) {
  var UserManagerService, user_api_uri;
  user_api_uri = '/api/users';
  UserManagerService = (function() {
    function UserManagerService() {}

    UserManagerService.prototype.get_current_user = function() {
      return $q(function(resolve, reject) {
        $http.get(user_api_uri + '/current').success(function(current_user, status, headers, config) {
          resolve(current_user);
        }).error(function(data, status, headers, config) {
          reject();
        });
      });
    };

    UserManagerService.prototype.change_workspace_path = function(user, path) {
      return $q(function(resolve, reject) {
        return $http.put(user_api_uri + '/' + user, {
          preferences: {
            workspace: {
              path: path
            }
          }
        }).success(function() {
          return resolve();
        }).error(function(data, status) {
          return reject(status);
        });
      });
    };

    UserManagerService.prototype.login = function(username, password) {
      return $q(function(resolve, reject) {
        $http.post('/login', {
          username: username,
          password: password
        }).success(function(data, status, headers, config) {
          if (authRequiredInterceptor.last_intercepted_path != null) {
            $location.path(authRequiredInterceptor.last_intercepted_path);
            return resolve();
          } else {
            $location.path('/');
            return resolve();
          }
        }).error(function(data, status, headers, config) {
          reject();
        });
      });
    };

    UserManagerService.prototype.logout = function() {
      return $q(function(resolve, reject) {
        $http.post('/logout').success(function(data, status, headers, config) {
          return resolve();
        }).error(function(data, status, headers, config) {
          reject();
        });
      });
    };

    return UserManagerService;

  })();
  return new UserManagerService;
};

var angular, app, app_name, app_obj,
  bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

angular = require('angular');

require('angular-route');

app = angular.module('harrogateIndexApp', ['ngRoute', 'ui.bootstrap']);

require('./app-catalog-provider.js').inject(app);

require('./buttons-only-modal-factory-service.js').inject(app);

require('./download-project-modal-factory-service.js').inject(app);

require('./filename-modal-factory-service.js').inject(app);

require('./terminal-directive.js').inject(app);

require('./round-slider-directive.js').inject(app);

require('./fileread-directive.js').inject(app);

require('./user-manager-service.js').inject(app);

// inject the apps
for (app_name in app_catalog) {
  app_obj = app_catalog[app_name];
  if (app_obj.angular_ctrl != null) {
    require(app_name).inject(app);
  }
}

// from http://stackoverflow.com/questions/14512583/how-to-generate-url-encoded-anchor-links-with-angularjs
app.filter('escape', function() {
  return window.encodeURIComponent;
});

app.filter('capitalize', function() {
  return function(input) {
    if (input != null) {
      return input.charAt(0).toUpperCase() + input.substr(1);
    } else {
      return '';
    }
  };
});

app.service('authRequiredInterceptor', [
  '$q', '$location', function($q, $location) {
    var AuthRequiredInterceptor;
    AuthRequiredInterceptor = (function() {
      function AuthRequiredInterceptor() {
        this.responseError = bind(this.responseError, this);
        this.last_intercepted_path = null;
      }

      AuthRequiredInterceptor.prototype.responseError = function(response) {
        if (response.status === 401) {
          this.last_intercepted_path = $location.path();
          $location.path('/apps/user');
        }
        return $q.reject(response);
      };

      return AuthRequiredInterceptor;

    })();
    return new AuthRequiredInterceptor;
  }
]);

app.controller('statusBarCtrl', [
  '$scope', 'UserManagerService', function($scope, UserManagerService) {
    return UserManagerService.get_current_user().then(function(current_user) {
      $scope.current_user = current_user;
    });
  }
]);

app.config([
  // redirect by default to home (let's hope that an app called 'home' always exists...)
  '$routeProvider', '$httpProvider', function($routeProvider, $httpProvider, $location) {
    $routeProvider.when('/', {
      redirectTo: '/apps/home'
    });

    // add the routes for the apps
    for (app_name in app_catalog) {
      app_obj = app_catalog[app_name];
      if (app_obj.angular_ctrl != null) {
        $routeProvider.when(app_obj.angularjs_route, {
          templateUrl: app_obj.nodejs_route,
          controller: require(app_name).controller,
          reloadOnSearch: false
        });
      } else {
        $routeProvider.when(app_obj.angularjs_route, {
          templateUrl: app_obj.nodejs_route
        });
      }
    }
    // setup 401 interception
    $httpProvider.interceptors.push('authRequiredInterceptor');
  }
]);

app.directive('setFocus', function($timeout, $parse) {
  return {
    restrict: "A",
    scope: {
      setFocus: '='
    },
    link: function($scope, element, attrs) {
      $scope.$watch('setFocus', function(value) {
        if (value === true) {
          $timeout(function() {
            element[0].focus();
          });
        }
      });
    }
  };
});

app.run();

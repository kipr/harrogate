exports.name = 'ShutdownViewController';

exports.inject = function(app) {
  app.controller(exports.name, ['$scope', '$http', '$location', 'ButtonsOnlyModalFactory', exports.controller]);
};

exports.controller = function($scope, $http, $location, ButtonsOnlyModalFactory) {
  $scope.shutting_down = false;
  return ButtonsOnlyModalFactory.open('Shut down the System', 'Are you sure you want to shut down the system?', ['Yes', 'No']).then(function(button) {
    if (button === 'Yes') {
      $scope.shutting_down = true;
      return $http.post('/api/shutdown');
    } else if (button === 'No') {
      return $location.path('/apps/home');
    }
  });
};

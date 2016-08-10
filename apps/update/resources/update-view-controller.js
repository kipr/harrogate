var code_mirror, io;

code_mirror = require('codemirror/lib/codemirror');

io = require('socket.io-client');

exports.name = 'UpdateViewController';

exports.inject = function(app) {
  app.controller(exports.name, ['$scope', '$http', 'AppCatalogProvider', 'ButtonsOnlyModalFactory', exports.controller]);
};

exports.controller = function($scope, $http, AppCatalogProvider, ButtonsOnlyModalFactory) {
  var events, socket;
  socket = void 0;
  events = void 0;
  $scope.updating = false;
  $scope.selected_script = {
    name: ''
  };
  $scope.scripts = [];
  $scope.update = function(script) {
    return ButtonsOnlyModalFactory.open('Update Packages', 'Are you sure you want to update packages?', ['Yes', 'No']).then(function(button) {
      if (button === 'Yes') {
        $scope.updating = true;
        return $http.post('/api/update', {
          script: script
        }).success(function() {
          return $scope.updating = false;
        }).error(function() {
          return $scope.updating = false;
        });
      }
    });
  };
  $http.get('/api/update', {}).success(function(data, status, headers, config) {
    return $scope.scripts = data;
  });
  AppCatalogProvider.catalog.then(function(app_catalog) {
    var events_namespace, ref, ref1, ref2, ref3;
    events = (ref = app_catalog['Update']) != null ? (ref1 = ref.event_groups) != null ? ref1.update_events.events : void 0 : void 0;
    events_namespace = (ref2 = app_catalog['Update']) != null ? (ref3 = ref2.event_groups) != null ? ref3.update_events.namespace : void 0 : void 0;
    if (events != null) {
      socket = io(':8888' + events_namespace);
      socket.on(events.stdout.id, function(msg) {
        $scope.$broadcast('update-output', msg);
      });
      socket.on(events.stderr.id, function(msg) {
        $scope.$broadcast('update-output', msg);
      });
    }
  });
  $scope.$on('update-input', function(event, text) {
    if ((socket != null) && (events != null)) {
      socket.emit(events.stdin.id, text);
    }
  });
};

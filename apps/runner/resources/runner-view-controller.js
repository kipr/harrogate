var CodeMirror, Io;

CodeMirror = require('codemirror/lib/codemirror');

Io = require('socket.io-client');

exports.name = 'RunnerViewController';

exports.inject = function(app) {
  app.controller(exports.name, ['$scope', '$http', '$location', 'AppCatalogProvider', 'ProgramService', exports.controller]);
};

exports.controller = function($scope, $http, $location, AppCatalogProvider, ProgramService) {
  var events, socket;
  $scope.ProgramService = ProgramService;
  socket = void 0;
  events = void 0;
  AppCatalogProvider.catalog.then(function(app_catalog) {
    var projects_resource, ref, ref1;
    projects_resource = (ref = app_catalog['Programs']) != null ? (ref1 = ref.web_api) != null ? ref1.projects : void 0 : void 0;
    if (projects_resource != null) {
      return $http.get(projects_resource.uri).success(function(data, status, headers, config) {
        var project, selected;
        $scope.ws = data;
        if ($location.search().project != null) {
          selected = (function() {
            var i, len, ref2, results;
            ref2 = $scope.ws.projects;
            results = [];
            for (i = 0, len = ref2.length; i < len; i++) {
              project = ref2[i];
              if (project.name === $location.search().project) {
                results.push(project);
              }
            }
            return results;
          })();
          if (selected[0]) {
            return $scope.select_project(selected[0]);
          }
        }
      });
    }
  });
  $scope.select_project = function(project) {
    // toggle selection
    if ($scope.selected_project === project) {
      return $scope.selected_project = null;
    } else {
      return $scope.selected_project = project;
    }
  };
  AppCatalogProvider.catalog.then(function(app_catalog) {
    var events_namespace, ref, ref1, ref2, ref3;
    events = (ref = app_catalog['Runner']) != null ? (ref1 = ref.event_groups) != null ? ref1.runner_events.events : void 0 : void 0;
    events_namespace = (ref2 = app_catalog['Runner']) != null ? (ref3 = ref2.event_groups) != null ? ref3.runner_events.namespace : void 0 : void 0;
    if (events != null) {
      socket = Io(':8888' + events_namespace);
      return socket.on(events.stdout.id, function(msg) {
        return $scope.$broadcast('runner-program-output', msg);
      });
    }
  });
  $scope.$on('runner-program-input', function(event, text) {
    if ((socket != null) && (events != null)) {
      return socket.emit(events.stdin.id, text);
    }
  });
  $scope.run = function() {
    if ($scope.selected_project != null) {
      $scope.img_src = null;
      $scope.$broadcast("runner-reset-terminal");
      return ProgramService.run($scope.selected_project.name);
    }
  };
  return $scope.stop = function() {
    return ProgramService.stop();
  };
};

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



  $scope.select_project = function(project) {
    // toggle selection
    if ($scope.selected_project === project) {
      return $scope.selected_project = null;
    } else {
      return $scope.selected_project = project;
    }
  };

  $scope.users = [
    {id: 0, name: 'Default User'}
  ];
  $scope.active_user = $scope.users[0];

  $scope.$watch('active_user', function(newValue, oldValue) {
    $scope.update_projects();
  });


  sort_users = function(users) {
    users.sort(
      function(a, b) {
        var nameA = a.name.toUpperCase();
        var nameB = b.name.toUpperCase();

        if (nameA === "DEFAULT USER"){
          return -1;
        }

        if (nameB === "DEFAULT USER"){
          return 1;
        }

        if (nameA < nameB) {
          return -1;
        }
        if (nameA > nameB) {
          return 1;
        }

        return 0;
      });

    return users;
  }

  $scope.update_projects = function() {
    var projects_resource, ref, ref1;
    AppCatalogProvider.catalog.then(function(app_catalog) {
      projects_resource = (ref = app_catalog['Programs']) != null ? (ref1 = ref.web_api) != null ? ref1.projects : void 0 : void 0;
      if (projects_resource != null) {
        return $http.get(projects_resource.uri + '/' + $scope.active_user.name).success(function(data, status, headers, config) {
          $scope.ws = data;
          $scope.ws.projects = ($scope.ws.projects || []).sort();
          if ($location.search().project != null) {
            var selected = (function() {
              var ref2 = $scope.ws.projects;
              var results = [];
              for (var i = 0, len = ref2.length; i < len; i++) {
                var project = ref2[i];
                if (project.name === $location.search().project) results.push(project);
              }
              return results;
            })();
            if (selected[0]) return $scope.select_project(selected[0]);
          }
          $http.get(projects_resource.uri + '/users').success(function(data, status, headers, config) {
            $scope.users = Object.keys(data).map(function(user, i) { return {id: i, name: user}; });
            $scope.users = sort_users($scope.users);
          });
        });
      }
    })
  }

  $scope.update_projects();

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
      $scope.is_compiling = false;
      $scope.img_src = null;
      $scope.$broadcast("runner-reset-terminal");
      return ProgramService.run($scope.selected_project.name, $scope.active_user.name);
    }
  };
  return $scope.stop = function() {
    return ProgramService.stop();
  };
};

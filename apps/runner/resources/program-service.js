var Io;

Io = require('socket.io-client');

exports.name = 'ProgramService';

exports.inject = function(app) {
  app.service(exports.name, ['$http', '$q', '$timeout', 'AppCatalogProvider', exports.service]);
};

exports.service = function($http, $q, $timeout, AppCatalogProvider) {
  var ProgramService, runner_api_uri, service;
  runner_api_uri = '/api/run';
  ProgramService = (function() {
    function ProgramService() {
      this.running = null;
      return;
    }

    ProgramService.prototype.run = function(project_name) {
      return $q(function(resolve, reject) {
        $http.post(runner_api_uri, {
          name: project_name
        }).success(function() {
          resolve();
        }).error(function() {
          reject();
        });
      });
    };

    ProgramService.prototype.stop = function() {
      return $q(function(resolve, reject) {
        $http["delete"]('/api/run/current').success(function() {
          resolve();
        }).error(function() {
          reject();
        });
      });
    };

    return ProgramService;

  })();
  service = new ProgramService;
  AppCatalogProvider.catalog.then(function(app_catalog) {
    var events, events_namespace, ref, ref1, ref2, ref3, socket;
    events = (ref = app_catalog['Runner']) != null ? (ref1 = ref.event_groups) != null ? ref1.runner_events.events : void 0 : void 0;
    events_namespace = (ref2 = app_catalog['Runner']) != null ? (ref3 = ref2.event_groups) != null ? ref3.runner_events.namespace : void 0 : void 0;
    if (events != null) {
      socket = Io(':8888' + events_namespace);
      socket.on(events.starting.id, function(name) {
        $timeout(function() {
          service.running = name;
        });
      });
      socket.on(events.ended.id, function() {
        return $timeout(function() {
          service.running = null;
        });
      });
      return;
    }
  });
  return service;
};

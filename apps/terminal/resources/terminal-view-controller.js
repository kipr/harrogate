var code_mirror, io;

code_mirror = require('codemirror/lib/codemirror');

io = require('socket.io-client');

exports.name = 'TerminalViewController';

exports.inject = function(app) {
  app.controller(exports.name, ['$scope', 'AppCatalogProvider', exports.controller]);
};

exports.controller = function($scope, AppCatalogProvider) {
  var events, socket;
  socket = void 0;
  events = void 0;
  AppCatalogProvider.catalog.then(function(app_catalog) {
    var events_namespace, ref, ref1, ref2, ref3;
    events = (ref = app_catalog['Terminal']) != null ? (ref1 = ref.event_groups) != null ? ref1.terminal_events.events : void 0 : void 0;
    events_namespace = (ref2 = app_catalog['Terminal']) != null ? (ref3 = ref2.event_groups) != null ? ref3.terminal_events.namespace : void 0 : void 0;
    if (events != null) {
      socket = io(':8888' + events_namespace);
      socket.on(events.stdout.id, function(msg) {
        $scope.$broadcast('terminal-output', msg);
      });
      socket.on(events.stderr.id, function(msg) {
        $scope.$broadcast('terminal-output', msg);
      });
    }
  });
  $scope.$on('terminal-input', function(event, text) {
    if ((socket != null) && (events != null)) {
      socket.emit(events.stdin.id, text);
    }
  });
  $scope.restart = function() {
    $scope.$broadcast('terminal-output', '\n\n\n');
    if ((socket != null) && (events != null)) {
      return socket.emit(events.restart.id);
    }
  };
};

code_mirror = require 'codemirror/lib/codemirror'
io = require 'socket.io-client'

exports.name = 'TerminalViewController'

exports.inject = (app) ->
  app.controller exports.name, [
    '$scope'
    'AppCatalogProvider'
    exports.controller
  ]
  return

exports.controller = ($scope, AppCatalogProvider) ->
  socket = undefined
  events = undefined

  AppCatalogProvider.catalog.then (app_catalog) ->
    events =  app_catalog['Terminal']?.event_groups?.terminal_events.events
    events_namespace =  app_catalog['Terminal']?.event_groups?.terminal_events.namespace
    if events?
      socket = io ':8888' + events_namespace

      socket.on events.stdout.id, (msg) ->
        $scope.$broadcast 'terminal-output', msg
        return

      socket.on events.stderr.id, (msg) ->
        $scope.$broadcast 'terminal-output', msg
        return

    return

  $scope.$on 'terminal-input', (event, text) ->
    if socket? and events?
      socket.emit events.stdin.id, text
    return

  $scope.restart = ->
    $scope.$broadcast 'terminal-output', '\n\n\n'

    if socket? and events?
      socket.emit events.restart.id

  return
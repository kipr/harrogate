code_mirror = require 'codemirror/lib/codemirror'
io = require 'socket.io-client'

exports.name = 'UpdateViewController'

exports.inject = (app) ->
  app.controller exports.name, [
    '$scope'
    '$http'
    'AppCatalogProvider'
    'ButtonsOnlyModalFactory'
    exports.controller
  ]
  return

exports.controller = ($scope, $http, AppCatalogProvider, ButtonsOnlyModalFactory) ->
  socket = undefined
  events = undefined

  $scope.updating = false
  $scope.selected_script = {name: ''}
  $scope.scripts = []

  $scope.update = (script) ->
    ButtonsOnlyModalFactory.open(
      'Update OS'
      'Are you sure you want to update packages?'
      [ 'Yes', 'No' ])
    .then (button) ->
      if button is 'Yes'
        $scope.updating = true
        $http.post('/api/update', {script: script})
        .success -> $scope.updating = false
        .error -> $scope.updating = false

  $http.get('/api/update', {}).success (data, status, headers, config) ->
    $scope.scripts = data

  AppCatalogProvider.catalog.then (app_catalog) ->
    events =  app_catalog['Update']?.event_groups?.update_events.events
    events_namespace =  app_catalog['Update']?.event_groups?.update_events.namespace
    if events?
      socket = io ':8888' + events_namespace

      socket.on events.stdout.id, (msg) ->
        $scope.$broadcast 'update-output', msg
        return

      socket.on events.stderr.id, (msg) ->
        $scope.$broadcast 'update-output', msg
        return

    return

  $scope.$on 'update-input', (event, text) ->
    if socket? and events?
      socket.emit events.stdin.id, text
    return

  return

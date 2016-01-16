code_mirror = require 'codemirror/lib/codemirror'
io = require 'socket.io-client'

exports.name = 'UpgradeViewController'

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

  $scope.upgrading = false
  $scope.selected_script = {name: ''}
  $scope.scripts = []

  $scope.upgrade = (script) ->
    ButtonsOnlyModalFactory.open(
      'Upgrade OS'
      'Are you sure you want to upgrade your OS?'
      [ 'Yes', 'No' ])
    .then (button) ->
      if button is 'Yes'
        $scope.upgrading = true
        $http.post('/api/upgrade', {script: script})

  $http.get('/api/upgrade', {}).success (data, status, headers, config) ->
    $scope.scripts = data

  AppCatalogProvider.catalog.then (app_catalog) ->
    events =  app_catalog['Upgrade']?.event_groups?.upgrade_events.events
    events_namespace =  app_catalog['Upgrade']?.event_groups?.upgrade_events.namespace
    if events?
      socket = io ':8888' + events_namespace

      socket.on events.stdout.id, (msg) ->
        $scope.$broadcast 'upgrade-output', msg
        return

      socket.on events.stderr.id, (msg) ->
        $scope.$broadcast 'upgrade-output', msg
        return

    return

  $scope.$on 'upgrade-input', (event, text) ->
    if socket? and events?
      socket.emit events.stdin.id, text
    return

  return

CodeMirror = require 'codemirror/lib/codemirror'
Io = require 'socket.io-client'

exports.name = 'RunnerViewController'

exports.inject = (app) ->
  app.controller exports.name, [
    '$scope'
    '$http'
    '$location'
    'AppCatalogProvider'
    'ProgramService'
    exports.controller
  ]
  return

exports.controller = ($scope, $http, $location,AppCatalogProvider, ProgramService) ->

  $scope.ProgramService = ProgramService

  socket = undefined
  events = undefined

  AppCatalogProvider.catalog.then (app_catalog) ->
    projects_resource = app_catalog['Programs']?.web_api?.projects
    if projects_resource?
      $http.get(projects_resource.uri)

      .success (data, status, headers, config) ->
        $scope.ws = data

        if $location.search().project?
          selected = (project for project in $scope.ws.projects when project.name is $location.search().project)
          if selected[0]
            $scope.select_project selected[0]

  $scope.select_project = (project) ->
    # toggle selection
    if $scope.selected_project is project
      $scope.selected_project = null
    else
      $scope.selected_project = project

  AppCatalogProvider.catalog.then (app_catalog) ->
    events =  app_catalog['Runner']?.event_groups?.runner_events.events
    events_namespace =  app_catalog['Runner']?.event_groups?.runner_events.namespace
    if events?
      socket = Io ':8888' + events_namespace

      socket.on events.stdout.id, (msg) ->
        $scope.$broadcast 'runner-program-output', msg

  $scope.$on 'runner-program-input', (event, text) ->
    if socket? and events?
      socket.emit events.stdin.id, text

  $scope.run = ->
    if $scope.selected_project?
      $scope.img_src = null
      $scope.$broadcast "runner-reset-terminal"
      ProgramService.run $scope.selected_project.name

  $scope.stop = ->
    ProgramService.stop()

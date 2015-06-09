code_mirror = require 'codemirror/lib/codemirror'
io = require 'socket.io-client'

exports.name = 'runner_view_controller'

exports.inject = (app) ->
  app.controller exports.name, [
    '$scope'
    '$http'
    'app_catalog_provider'
    exports.controller
  ]
  exports.controller

exports.controller = ($scope, $http, app_catalog_provider) ->
  socket = undefined
  events = undefined
  editor = undefined

  editor = code_mirror.fromTextArea(document.getElementById('runner'),
    lineNumbers: false
    theme: 'eclipse'
  )

  app_catalog_provider.catalog.then (app_catalog) ->
    projects_resource = app_catalog['Programs']?.web_api?.projects
    if projects_resource?
      $http.get(projects_resource.uri)
      .success (data, status, headers, config) ->
        $scope.ws = data
        return
      .error (data, status, headers, config) ->
        console.log "Could not get #{uri}"
        return
    return

  $scope.select_project = (project) ->
    # toggle selection
    if $scope.selected_project is project
      $scope.selected_project = null
    else
      $scope.selected_project = project
    return

  append_text = (text) ->
    if editor?
      editor.replaceRange text, code_mirror.Pos(editor.lastLine())
      editor.setCursor editor.lineCount(), 0
    return

  app_catalog_provider.catalog.then (app_catalog) ->
    events =  app_catalog['Runner']?.event_groups?.runner_events.events
    events_namespace =  app_catalog['Runner']?.event_groups?.runner_events.namespace
    if events?
      socket = io ':8888' + events_namespace

      socket.on events.stdout.id, (msg) ->
        append_text msg
        return

      socket.on events.stderr.id, (msg) ->
        append_text msg
        return

    return

  $scope.restart = ->
    return

  $scope.launch = ->
    if $scope.selected_project?
      $http.post('/api/run', {name: $scope.selected_project.name})
      .success (data, status, headers, config) ->
        return
      .error (data, status, headers, config) ->
        console.log "Could not post to /api/run"
        return
    return

  return
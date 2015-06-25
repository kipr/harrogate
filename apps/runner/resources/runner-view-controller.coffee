CodeMirror = require 'codemirror/lib/codemirror'
Io = require 'socket.io-client'

exports.name = 'RunnerViewController'

exports.inject = (app) ->
  app.controller exports.name, [
    '$scope'
    '$http'
    'AppCatalogProvider'
    exports.controller
  ]
  return

exports.controller = ($scope, $http, AppCatalogProvider) ->
  socket = undefined
  events = undefined
  editor = undefined

  $scope.console_mode = true

  $scope.show_console = ->
    $scope.console_mode = true
    return

  $scope.show_gui = ->
    $scope.console_mode = false
    return

  $scope.gui_mousemove = ($event) ->
    socket.emit events.gui_input.id, {mouse: {x: $event.offsetX, y: $event.offsetY}}
    return

  $scope.gui_keypress = ($event) ->
    return

  window.addEventListener 'keydown', (event) ->
    return

  editor = CodeMirror.fromTextArea(document.getElementById('runner'),
    lineNumbers: false
    theme: 'eclipse'
  )

  AppCatalogProvider.catalog.then (app_catalog) ->
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
      editor.replaceRange text, CodeMirror.Pos(editor.lastLine())
      editor.setCursor editor.lineCount(), 0
    return

  AppCatalogProvider.catalog.then (app_catalog) ->
    events =  app_catalog['Runner']?.event_groups?.runner_events.events
    events_namespace =  app_catalog['Runner']?.event_groups?.runner_events.namespace
    if events?
      socket = Io ':8888' + events_namespace

      socket.on events.stdout.id, (msg) ->
        append_text msg
        return

      socket.on events.stderr.id, (msg) ->
        append_text msg
        return

      socket.on events.frame.id, (msg) ->
        $scope.$apply ->
          $scope.img_src = "data:image/png;base64,#{msg}"
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

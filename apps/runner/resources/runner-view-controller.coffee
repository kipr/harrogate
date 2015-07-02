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
  img_width = undefined
  img_height = undefined

  $scope.console_mode = true

  $scope.show_console = ->
    $scope.console_mode = true
    return

  $scope.show_gui = ->
    $scope.console_mode = false
    return

  $scope.gui_mousemove = ($event) ->
    return if not img_width or not img_height

    client_rect = document.getElementById('graphics_window').getBoundingClientRect()

    x = ($event.clientX - client_rect.left) / client_rect.width * img_width
    y = ($event.clientY - client_rect.top) / client_rect.height * img_height

    x = img_width if x > img_width
    x = 0 if x < 0

    y = img_height if y > img_height
    y = 0 if y < 0

    socket.emit events.gui_input.id, {mouse: pos: {x: x | 0, y: y | 0}}
    return

  $scope.gui_mousedown = ($event) ->

    msg = mouse: { button_down: {} }
    switch $event.which
      when 1 then msg.mouse.button_down['left'] = true
      when 2 then msg.mouse.button_down['middle'] = true
      when 3 then msg.mouse.button_down['right'] = true
    socket.emit events.gui_input.id, msg

    $event.preventDefault()
    return

  $scope.gui_mouseup = ($event) ->

    msg = mouse: { button_down: {} }
    switch $event.which
      when 1 then msg.mouse.button_down['left'] = false
      when 2 then msg.mouse.button_down['middle'] = false
      when 3 then msg.mouse.button_down['right'] = false
    socket.emit events.gui_input.id, msg

    $event.preventDefault()
    return

  pressed_keys = []

  document.getElementById('graphics_window').addEventListener 'keydown', (event) ->
    if pressed_keys.indexOf(event.keyCode) is -1
      pressed_keys.push event.keyCode
      msg = keyboard: { key_pressed: pressed_keys }
      socket.emit events.gui_input.id, msg

    event.preventDefault()
    return false

  document.getElementById('graphics_window').addEventListener 'keyup', (event) ->
    pressed_keys.splice index, 1 if (index = pressed_keys.indexOf event.keyCode) isnt -1
    msg = keyboard: { key_pressed: pressed_keys }
    socket.emit events.gui_input.id, msg

    event.preventDefault()
    return false

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
        img_width = msg.width
        img_height = msg.height

        $scope.$apply ->
          $scope.img_src = "data:image/png;base64,#{msg.data}"
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

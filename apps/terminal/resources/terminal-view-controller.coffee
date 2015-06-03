code_mirror = require 'codemirror/lib/codemirror'
io = require 'socket.io-client'

exports.name = 'terminal_view_controller'

exports.inject = (app) ->
  app.controller exports.name, ['$scope', 'app_catalog_provider', exports.controller]
  exports.controller

exports.controller = ($scope, app_catalog_provider) ->
  socket = undefined
  events = undefined
  editor = undefined
  read_only_ch = -1

  on_enter = (e) ->
    if socket? and events?
      socket.emit events.stdin.id, e.getLine(e.lastLine()).substring(read_only_ch + 1)

    read_only_ch = -1

    return code_mirror.Pass

  editor = code_mirror.fromTextArea(document.getElementById('terminal'),
    lineNumbers: false
    theme: 'eclipse'
    extraKeys:
      Enter: on_enter
  )

  editor.on 'beforeChange', (e, obj) ->
    # allow only changes to the last line
    if obj.to.line isnt e.lastLine()
      obj.cancel()
      return
    # and only after read_only_ch
    if obj.to.ch <= read_only_ch
      obj.cancel()
      return
    return

  append_text = (text) ->
    if editor?
      editor.replaceRange text, code_mirror.Pos(editor.lastLine())
      editor.setCursor editor.lineCount(), 0
      read_only_ch = editor.getCursor().ch - 1
    return

  app_catalog_provider.catalog.then (app_catalog) ->
    events =  app_catalog['Terminal']?.event_groups?.terminal_events.events
    events_namespace =  app_catalog['Terminal']?.event_groups?.terminal_events.namespace
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
    append_text '\n\n\n'

    if socket? and events?
      socket.emit events.restart.id

  return
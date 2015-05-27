code_mirror = require 'codemirror/lib/codemirror'
io = require 'socket.io-client'

exports.name = 'terminal_view_controller'

exports.inject = (app) ->
  app.controller exports.name, ['$scope', '$location', '$http', 'app_catalog_provider', exports.controller]
  exports.controller

exports.controller = ($scope, $location, $http, app_catalog_provider) ->
  socket = undefined
  terminal_event_group = undefined
  read_only_ch = -1

  on_enter = (e) ->
    if socket? and terminal_event_group?
      socket.emit terminal_event_group.events.stdin.id, e.getLine(e.lastLine()).substring(read_only_ch + 1)

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

  app_catalog_provider.catalog.then (app_catalog) ->
    terminal_event_group =  app_catalog['Terminal']?.event_groups?.terminal_events
    if terminal_event_group?
      socket = io ':8888' + terminal_event_group.namespace

      socket.on terminal_event_group.events.stdout.id, (msg) ->
        editor.replaceRange msg, code_mirror.Pos(editor.lastLine())
        editor.setCursor editor.lineCount(), 0
        read_only_ch = editor.getCursor().ch - 1
        return

      socket.on terminal_event_group.events.stderr.id, (msg) ->
        editor.replaceRange msg, code_mirror.Pos(editor.lastLine())
        editor.setCursor editor.lineCount(), 0
        read_only_ch = editor.getCursor().ch - 1
        return

    return

  return
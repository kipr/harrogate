code_mirror = require 'codemirror/lib/codemirror'

exports.name = 'terminal_view_controller'

exports.inject = (app) ->
  app.controller exports.name, ['$scope', '$location', '$http', 'app_catalog_provider', exports.controller]
  exports.controller

exports.controller = ($scope, $location, $http, app_catalog_provider) ->
  socket = undefined
  read_only_ch = -1

  on_enter = (e) ->
    if socket? and socket.readyState is WebSocket.OPEN
      socket.send e.getLine(e.lastLine()).substring(read_only_ch + 1)

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
    wss_port = app_catalog['Terminal']?.config?.terminal_wss_port
    if wss_port?
      socket = new WebSocket("ws://#{location.hostname}:#{wss_port}")

      socket.onmessage = (msg) ->
        editor.replaceRange msg.data, code_mirror.Pos(editor.lastLine())
        editor.setCursor editor.lineCount(), 0
        read_only_ch = editor.getCursor().ch - 1
        return

      # close socket if we leave the view
      $scope.$on '$locationChangeStart', (e) ->
        socket.close()
        socket = undefined
        return
    return

  return
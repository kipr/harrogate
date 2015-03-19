exports.name = 'camera_view_controller'

exports.inject = (app) ->
  app.controller exports.name,
    [
      '$scope'
      exports.controller
    ]
  exports.controller

exports.controller = ($scope) ->
  socket = new WebSocket("ws://#{location.hostname}:8375")

  socket.onopen = ->
    console.log 'socket open'

  socket.onmessage = (m) ->
    displays = JSON.parse m.data
    pids = Object.keys displays
    console.log displays[pids[0]]
    t = displays[pids[0]]
    $('#graphics').attr 'width', t.width
    $('#graphics').attr 'height', t.height
    $('#graphics').attr 'src', "data:image/jpeg;base64,#{t.data}"
  return 
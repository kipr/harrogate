socket = new WebSocket('ws://localhost:8080/')

req =
  to: 'springboard'
  func: 'list_apps'

socket.onopen = ->
  console.log 'socket open'
  socket.send(JSON.stringify req)

socket.onmessage = (msg) ->
  console.log msg

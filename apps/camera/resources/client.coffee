socket = new WebSocket("ws://#{location.hostname}:8374")

socket.onopen = ->
  console.log 'socket open'

socket.onmessage = (m) ->
  $('#camera').attr 'src', "data:image/jpeg;base64,#{m.data}"

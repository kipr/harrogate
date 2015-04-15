net = require 'net'
assert = require 'assert'
zlib = require 'zlib'
WebSocketServer = require('ws').Server

displays = {}

handle_display_packet = (packet) ->
  total  = packet.readInt32LE 0
  pid    = packet.readInt32LE 4
  width  = packet.readInt32LE 8
  height = packet.readInt32LE 12
  size   = packet.readInt32LE 16
  assert.equal packet.length, total
  
  raw = packet.slice total - size
  
  zlib.inflate raw, (e, b) ->
    img = new Buffer(original_data, 'binary').toString('base64')
  
    displays[pid] =
      'width': width
      'height': height
      'data': img
  
  pid

display_server = net.createServer (sock) ->
  incoming = new Buffer 0
  pids = []
    
  # Add a 'data' event handler to this instance of socket
  sock.on 'data', (data) ->
    incoming = Buffer.concat [incoming, data]
    if incoming.length >= 4
      total  = incoming.readInt32LE 0
      assert total >= 0, "A negative packet size makes no sense (#{total})"
      if incoming.length >= total
        packet = incoming.slice 0, total
        pid = handle_display_packet packet
        pids.push pid if pids.indexOf(pid) < 0
        incoming = incoming.slice total
    
  sock.on 'close', (data) ->
    incoming = null
    console.log "Cleaning up keys: #{pids}"
    for pid in pids
      delete displays[pid]

# display_server.listen 60000

module.exports =
  exec: ->
    wss = new WebSocketServer(port: 8375)

    wss.broadcast = (data) ->
      wss.clients.forEach (client) ->
        client.send(data);

    broadcastDisplays = ->
      wss.broadcast(JSON.stringify displays)
      setTimeout(broadcastDisplays, 25)

    broadcastDisplays()
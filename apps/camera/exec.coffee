Worker = require('webworker-threads').Worker
boyd = require 'node-boyd'
fs = require 'fs'
url = require 'url'
path_tools = require 'path'
WebSocketServer = require('ws').Server

cam = undefined
wss = undefined

module.exports =
  exec: ->
    wss = new WebSocketServer(port: 8374)

    wss.broadcast = (data) ->
      wss.clients.forEach (client) ->
        client.send(data);

    cam = boyd.open()

    console.log cam

    broadcastImage = ->
      wss.broadcast(boyd.getImage(cam.handle))
      setTimeout(broadcastImage, 25)

    if cam.success
      broadcastImage()
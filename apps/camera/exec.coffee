boyd = require 'node-boyd'
fs = require 'fs'
url = require 'url'
path_tools = require 'path'
WebSocketServer = require('ws').Server

cam = undefined
wss = undefined
closing = false # signal that the app is closing

module.exports =
  exec: ->
    wss = new WebSocketServer(port: 8374)

    wss.broadcast = (data) ->
      wss.clients.forEach (client) ->
        client.send(data);

    cam = boyd.open()

    console.log cam

    broadcastImage = ->
      if !closing
        wss.broadcast(boyd.getImage(cam.handle))
        setTimeout(broadcastImage, 25)

    if cam.success
      broadcastImage()

  closing: ->
    closing = true

    # wait to avoid race conditions with broadcastImage
    setTimeout (->
      wss.close() if wss?
      wss = undefined

      boyd.close(cam.handle) if cam?
      cam = undefined

      return
    ), 30

    return
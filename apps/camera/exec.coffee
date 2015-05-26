boyd = require 'node-boyd'
fs = require 'fs'
url = require 'url'
path_tools = require 'path'
WebSocketServer = require('ws').Server

AppCatalog = require '../../shared/scripts/app-catalog.coffee'

cam = undefined
wss = undefined

module.exports =
  exec: ->
    wss_port = AppCatalog.catalog['Camera'].config.camera_wss_port
    console.log "Starting camera web socket server at port #{wss_port}"
    wss = new WebSocketServer(port: wss_port)

    wss.on 'connection', (ws) ->
      cam = boyd.open() if not cam

      sendImage = ->
        try
          ws.send(boyd.getImage(cam.handle))
          setTimeout(sendImage, 25)
        catch
          # the socket was closed
          # close the cam if there are no more clients
          if wss.clients.length is 0
            boyd.close(cam.handle) if cam?
            cam = undefined
        return

      if cam.success
        sendImage()

      return

  closing: ->
    wss.close() if wss?
    wss = undefined
    return
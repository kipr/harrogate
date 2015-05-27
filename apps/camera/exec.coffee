boyd = require 'node-boyd'
fs = require 'fs'
url = require 'url'
path_tools = require 'path'

AppCatalog = require '../../shared/scripts/app-catalog.coffee'

camera_event_group = AppCatalog.catalog['Camera'].event_groups.camera_events

cam = undefined
wss = undefined
clients = 0

module.exports =
  camera_on_connection: (socket) ->
    clients++
    cam = boyd.open() if not cam

    sendImage = ->
      try
        socket.emit camera_event_group.events.frame_arrived.id, boyd.getImage(cam.handle)
        setTimeout(sendImage, 25)
      return

    if cam.success
      sendImage()

    socket.on 'disconnect', ->
      clients--
      # the socket was closed
      # close the cam if there are no more clients
      if clients is 0
        boyd.close(cam.handle) if cam?
        cam = undefined
      return

    return

  exec: ->
    return

  closing: ->
    wss.close() if wss?
    wss = undefined
    return
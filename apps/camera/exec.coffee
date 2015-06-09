boyd = require 'node-boyd'
fs = require 'fs'
url = require 'url'
path_tools = require 'path'

AppCatalog = require '../../shared/scripts/app-catalog.coffee'

events = AppCatalog.catalog['Camera'].event_groups.camera_events.events

cam = undefined
clients = 0

camera_on_connection = (socket) ->
  clients++
  cam = boyd.open() if not cam

  sendImage = ->
    try
      socket.emit events.frame_arrived.id, boyd.getImage(cam.handle)
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

module.exports =
  event_init: (event_group_name, namespace) ->
    namespace.on 'connection', camera_on_connection
    return

  exec: ->
    return
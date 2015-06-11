Boyd = require 'node-boyd'

AppCatalog = require '../../shared/scripts/app-catalog.coffee'

events = AppCatalog.catalog['Camera'].event_groups.camera_events.events

clients = 0

module.exports =

  event_init: (event_group_name, namespace) ->

    namespace.on 'connection', (socket) ->
      clients++
      cam = Boyd.open() unless cam

      sendImage = ->
        try
          socket.emit events.frame_arrived.id, Boyd.getImage(cam.handle)
          setTimeout sendImage, 25
        return

      if cam.success
        sendImage()

      socket.on 'disconnect', ->
        clients--
        # the socket was closed
        # close the cam if there are no more clients
        if clients is 0
          Boyd.close cam.handle if cam?
          cam = undefined
        return

      return

    return

  exec: ->
    return

  closing: ->
    Boyd.close cam.handle if cam?
    cam = undefined
    return
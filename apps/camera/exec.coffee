daylite    = require_harrogate_module '/shared/scripts/daylite.coffee'
AppCatalog = require_harrogate_module '/shared/scripts/app-catalog.coffee'

Png = require('png').Png;

events = AppCatalog.catalog['Camera'].event_groups.camera_events.events

clients = 0

latest_camera_frame = null

daylite.subscribe 'camera/frame_data', (msg) ->
  png = new Png(msg.data, msg.height, msg.height, 'bgr');
  png.encode (data, error) ->
    if error
      console.log "Error: #{error.toString()}"
      return
    latest_camera_frame = data.toString('binary')
    console.log "Successfully got new frame from boyd"

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
    return

    Boyd.close cam.handle if cam?
    cam = undefined
    return
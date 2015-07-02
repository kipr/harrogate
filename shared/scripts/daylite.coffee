Bson = require 'bson'
EventEmitter = require('events').EventEmitter
Net = require 'net'

class DayliteClient extends EventEmitter
  constructor: ->
    @client = null

  join_daylite: (port) =>

    @client = Net.createConnection port, =>
      @emit 'connected'

      buffer = null

      @client.on 'data', (data) =>
        # append data
        buffer = if buffer then Buffer.concat [buffer, data] else data
        # how much data do we expect?
        packet_size = buffer.readInt32LE 0, 4

        # if we gont enough
        if buffer.length >= packet_size
          packet_data = buffer.slice 0, packet_size

          # emit the frame
          doc = Bson.BSONPure.BSON.deserialize packet_data
          @emit 'data', doc.topic, doc.msg

          if buffer.length isnt packet_size
            buffer = buffer.slice packet_size
          else
            buffer = null
        return

      @client.on 'close', =>
        @client = null
        @emit 'close'
        return

      @client.on 'error', (e) =>
        @emit 'error', e
        return

      return

    return

  leave_daylite: =>
    @client = null
    return

  publish: (topic, msg) =>
    if @client?
      doc =
        topic: topic
        msg: msg

      @client.write Bson.BSONPure.BSON.serialize(doc, false, true, true)
    return

  subscribe: (topic, cb) =>

    @on 'data', (t, msg) ->
      cb(msg) if t is topic
      return

    return

module.exports =
  DayliteClient: DayliteClient

Net = require 'net'

class DayliteClient
  constructor: ->
    @client = new Net.Socket()

    @client.on 'error', (error) =>
      console.log error

  connect: () =>
    try
      @client.connect 8374, '127.0.0.1', =>
        console.log 'connected'
    catch e
      console.log e
      return

    return @client

module.exports = new DayliteClient

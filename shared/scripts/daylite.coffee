if not process.env.COMPILE
  Daylite = require 'node-daylite'
  client = new Daylite.DayliteClient
  connect_to_daylite = ->
    client.join_daylite 8374
  setTimeout connect_to_daylite, 100
  process.on 'exit', (code) -> client.stop()
module.exports = client 
Worker = require('webworker-threads').Worker
boyd = require 'node-boyd'
jade = require 'jade'
fs = require 'fs'
url = require 'url'
path_tools = require 'path'

WebSocketServer = require('ws').Server
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

index = jade.compile(fs.readFileSync('apps/camera/index.jade', 'utf8'), filename: "./apps/camera/index.jade")

module.exports =
  handle: (request, response) ->
    path = url.parse(request.url).pathname
    name = path_tools.basename(path)
    if name is 'camera'
      response.writeHead 200, { 'Content-Type': 'text/html' }
      return response.end index(), 'utf8'
    response.writeHead 404, { 'Content-Type': 'text/plain' }
    response.end 'Pade not found\n'
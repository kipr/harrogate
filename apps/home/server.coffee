url = require 'url'
path_tools = require 'path'
jade = require 'jade'
fs = require 'fs'

app_categories = {}

index = jade.compile(fs.readFileSync('apps/home/index.jade', 'utf8'), filename: "./apps/home/index.jade")

module.exports =
  handle: (request, response) ->
    path = url.parse(request.url).pathname
    name = path_tools.basename(path)
    console.log name
    if name is 'home'
      response.writeHead 200, { 'Content-Type': 'text/html' }
      return response.end index(apps: app_categories), 'utf8'
      
    response.writeHead 404, { 'Content-Type': 'text/plain' }
    response.end 'Pade not found\n'
  update_apps: (apps) ->
    app_categories = {}
    for app in Object.keys apps
      c = apps[app]['category']
      app_categories[c] = [] if app_categories[c] is undefined
      app_categories[c].push apps[app]
    return
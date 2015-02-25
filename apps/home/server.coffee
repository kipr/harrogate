url = require 'url'
path_tools = require 'path'
jade = require 'jade'
fs = require 'fs'
app_catalog = require '../../shared/scripts/app-catalog.coffee'

app_categories = []

index = jade.compile(fs.readFileSync('apps/home/index.jade', 'utf8'), filename: "./apps/home/index.jade")

category_index = (name) ->
  for i in [0 .. app_categories.length - 1]
    return i if app_categories[i]['name'] is name
  return -1

cats = JSON.parse(fs.readFileSync 'apps/categories.json', 'utf8')
for c in cats
  app_categories.push
    name: c
    list: []
for app_name, app of app_catalog.catalog
  # Skip hidden apps
  if not app['hidden']
    c = app['category']
    i = category_index c
    if i < 0
      console.log "Warning: Please add #{c} to categories.json"
      app_categories.push
        name: c
        list: []
    app_categories[i]['list'].push app
      
# Sort the apps by priority
for i in [0 .. app_categories.length - 1]
  app_categories[i]['list'].sort (a, b) -> a.priority - b.priority

module.exports =
  handle: (request, response) ->
    path = url.parse(request.url).pathname
    name = path_tools.basename(path)
    if name is 'home'
      response.writeHead 200, { 'Content-Type': 'text/html' }
      return response.end index(apps: app_categories), 'utf8'
      
    response.writeHead 404, { 'Content-Type': 'text/plain' }
    response.end 'Pade not found\n'
    return
fs = require('fs')
express = require('express')
cookieParser = require('cookie-parser')

app_catalog = require './shared/scripts/app-catalog.coffee'

# set env, get config
env = process.env.NODE_ENV = process.env.NODE_ENV or 'development'
config = require('./config/server/config.js')

# create the app
harrogate_app = express()
harrogate_app.use cookieParser()

# Route to static content
harrogate_app.use express.static(__dirname + '/public')

# Serve /apps/catalog.json
harrogate_app.use '/apps/catalog.json', (request, response, next) ->
  app_catalog.handle request, response

# Start the apps
for app_name, app of app_catalog.catalog
  console.log "Starting #{app_name}"
  app_instance = require app['exec_path']
  app_instance.exec() if app_instance['exec']?

# Start the server
server = harrogate_app.listen config.port, ->
  console.log "Starting express.js server (#{server.address().address}:#{server.address().port})"
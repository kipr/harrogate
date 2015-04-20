fs = require 'fs'
express = require 'express'
cookie_parser = require 'cookie-parser'
bodyParser = require 'body-parser'
session = require 'express-session'
passport = require 'passport'
BasicStrategy =  require('passport-http').BasicStrategy
ON_DEATH = require 'death'

app_catalog = require './shared/scripts/app-catalog.coffee'

# set env, get config
env = process.env.NODE_ENV = process.env.NODE_ENV or 'development'
config = require('./config/server/config.js')

# create the app
harrogate_app = express()
harrogate_app.use cookie_parser()
harrogate_app.use bodyParser.json({limit: '5mb'})
harrogate_app.use session(secret: 'B on harrogate')
harrogate_app.use passport.initialize()

# setup passport
passport.use new BasicStrategy (username, password, done) ->
  if password is 'test'
    done null, username
  else
    done null, false

# All the /app stuff requires auth
harrogate_app.use '/apps', passport.authenticate('basic', {session: false}), (request, response, next) ->
  next()

# Serve /apps/catalog.json
harrogate_app.use '/apps/catalog.json', (request, response, next) ->
  app_catalog.handle request, response

# Init the apps
for app_name, app of app_catalog.catalog
  if app.get_instance()['init']?
    console.log "Init #{app_name}"
    app.get_instance().init(app)

# Register app web-api routes
for app_name, app of app_catalog.catalog
  if app.web_api?
    for api of app.web_api
      if app.web_api[api].router?
        console.log "Add Route: #{app.web_api[api].uri} --> #{app_name}"
        harrogate_app.use app.web_api[api].uri, app.web_api[api].router
      else
        console.warn "Warning: App #{app_name} defines web api '#{api}' but no router"

# Start the apps
for app_name, app of app_catalog.catalog
  console.log "Starting #{app_name}"
  app.get_instance().exec() if app.get_instance()['exec']?

# Route to static content
harrogate_app.use express.static(__dirname + '/public')

# Error handling
harrogate_app.use (error, request, response, next) ->
  # Body Parser error
  if error instanceof SyntaxError
    response.writeHead 400, { 'Content-Type': 'application/json' }
    return response.end "#{JSON.stringify(error: 'Malformed syntax, could not parse request')}", 'utf8'

  # Server error?!
  console.error '!!!!INTERNAL SERVER ERROR!!!!'
  console.error error
  console.error 'Stack Trace:'
  console.error error.stack

  response.writeHead 500
  return response.end()

# Start the server
server = harrogate_app.listen config.port, ->
  console.log "Starting express.js server (#{server.address().address}:#{server.address().port})"

ON_DEATH (signal, err) ->
  console.log "Stopping express.js server"
  server.close()

  # Stop apps
  for app_name, app of app_catalog.catalog
    console.log "Stopping #{app_name}"
    app.get_instance().closing() if app.get_instance()['closing']
  return
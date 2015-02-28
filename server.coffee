fs = require 'fs'
express = require 'express'
cookieParser = require 'cookie-parser'
bodyParser = require 'body-parser'
session = require 'express-session'
passport = require 'passport'
BasicStrategy =  require('passport-http').BasicStrategy

app_catalog = require './shared/scripts/app-catalog.coffee'

# set env, get config
env = process.env.NODE_ENV = process.env.NODE_ENV or 'development'
config = require('./config/server/config.js')

# create the app
harrogate_app = express()
harrogate_app.use cookieParser()
harrogate_app.use bodyParser()
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

# Start the apps
for app_name, app of app_catalog.catalog
  console.log "Starting #{app_name}"
  app_instance = require app['exec_path']
  app_instance.exec() if app_instance['exec']?

# Route to static content
harrogate_app.use express.static(__dirname + '/public')

# Start the server
server = harrogate_app.listen config.port, ->
  console.log "Starting express.js server (#{server.address().address}:#{server.address().port})"
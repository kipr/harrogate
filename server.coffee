fs = require 'fs'
http = require 'http'
express = require 'express'
cookie_parser = require 'cookie-parser'
bodyParser = require 'body-parser'
session = require 'express-session'
passport = require 'passport'
LocalStrategy =  require('passport-local').Strategy
ON_DEATH = require 'death'

app_catalog = require './shared/scripts/app-catalog.coffee'
SettingsManager = require './shared/scripts/settings-manager.coffee'
User = require './shared/scripts/user.coffee'
UserManager = require './shared/scripts/user-manager.coffee'

# create the app
harrogate_app = express()
harrogate_app.use cookie_parser()
harrogate_app.use bodyParser.json({limit: '5mb'})
harrogate_app.use session(
  secret: 'B on harrogate'
  resave: false
  saveUninitialized: true
)
harrogate_app.use passport.initialize()
harrogate_app.use passport.session()

# create the server
server = http.createServer harrogate_app

# create the socket.io object
io = require('socket.io')(server)

# setup passport
passport.serializeUser (user, done) ->
  done null, user
  return

passport.deserializeUser (user, done) ->
  done null, user
  return

passport.use new LocalStrategy (username, password, done) ->
  if not username?
    return done null, false

  if password is 'test'
     # create a new user if it is not existing
    if not UserManager.users[username]?
      UserManager.add_user new User(username)

    return done null, username
  else
    return done null, false

check_authenticated = (request, response, next) ->
  if request.isAuthenticated()

    # add the logged_in_user to the request
    if UserManager.users[request.user]?
      request.logged_in_user = UserManager.users[request.user]
    else # should never happen
      console.log "Unexpected user: #{request.user}"

    return next()
  else
    response.writeHead 401, { 'Content-Type': 'application/json' }
    response.end "#{JSON.stringify(error: 'Authentication required')}", 'utf8'
    return

# handling login
harrogate_app.post '/login', passport.authenticate('local'),  (request, response, next) ->
  response.writeHead 204
  return response.end()

# handling logout
harrogate_app.post '/logout', (request, response, next) ->
  request.logout()
  response.writeHead 204
  return response.end()

# All the /api routes need auth!!
harrogate_app.use '/api', check_authenticated, (request, response, next) ->
  next()

# Serve /apps/catalog.json
harrogate_app.get '/apps/catalog.json', (request, response, next) ->
  app_catalog.handle request, response

# Init the apps
for app_name, app of app_catalog.catalog
  if app.get_instance()['init']?
    console.log "Init #{app_name}"
    app.get_instance().init(app)

# Register the events
for app_name, app of app_catalog.catalog
  if app.event_groups?
    for event_group_name of app.event_groups
      event_group = app.event_groups[event_group_name]
      if event_group.namespace? and app.get_instance()[event_group.on_connection]?
        console.log "Add Event Namespace: #{event_group.namespace} --> #{app_name}"
        ns = io.of event_group.namespace
        ns.on 'connection', app.get_instance()[event_group.on_connection]
      else
        console.warn "Warning: App #{app_name} has malformed event definitions"

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
server.listen SettingsManager.settings.server.port, ->
  console.log "Starting express.js server (#{server.address().address}:#{server.address().port})"

ON_DEATH (signal, err) ->
  console.log "Stopping express.js server"
  server.close()

  # Stop apps
  for app_name, app of app_catalog.catalog
    console.log "Stopping #{app_name}"
    app.get_instance().closing() if app.get_instance()['closing']
  return
BodyParser = require 'body-parser'
CookieParser = require 'cookie-parser'
Express = require 'express'
Http = require 'http'
LocalStrategy =  require('passport-local').Strategy
Mkdirp = require 'mkdirp'
ON_DEATH = require 'death'
Os = require 'os'
Passport = require 'passport'
Path = require 'path'
Session = require 'express-session'

AppCatalog = require './shared/scripts/app-catalog.coffee'
SettingsManager = require './shared/scripts/settings-manager.coffee'
ServerError = require './shared/scripts/server-error.coffee'
User = require './shared/scripts/user.coffee'
UserManager = require './shared/scripts/user-manager.coffee'

# Hack to create the workspace
if Os.platform() is 'win32'
  workspace_path = Path.join process.env['USERPROFILE'], 'Documents', 'KISS'
else
  workspace_path = Path.join process.env['HOME'], 'Documents', 'KISS'

Mkdirp.sync workspace_path
Mkdirp.sync Path.join(workspace_path, 'bin')
Mkdirp.sync Path.join(workspace_path, 'data')
Mkdirp.sync Path.join(workspace_path, 'include')
Mkdirp.sync Path.join(workspace_path, 'lib')
Mkdirp.sync Path.join(workspace_path, 'src')

console.log 'Workspace @ #{workspace_path}'

# create the app
harrogate_app = Express()
harrogate_app.use CookieParser()
harrogate_app.use BodyParser.json({limit: '5mb'})
harrogate_app.use Session(
  secret: 'B on harrogate'
  resave: false
  saveUninitialized: true
)
harrogate_app.use Passport.initialize()
harrogate_app.use Passport.session()

# create the server
server = Http.createServer harrogate_app

# create the socket.io object
io = require('socket.io')(server)

# setup passport
Passport.serializeUser (user, done) ->
  done null, user
  return

Passport.deserializeUser (user, done) ->
  done null, user
  return

Passport.use new LocalStrategy (username, password, done) ->
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

  # bypass authentication system for now
  request.logged_in_user = new User 'Dummy'
  return next()

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
harrogate_app.post '/login', Passport.authenticate('local'),  (request, response, next) ->
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
  AppCatalog.handle request, response

# Init the apps
for app_name, app of AppCatalog.catalog
  if app.get_instance()['init']?
    console.log "Init #{app_name}"
    app.get_instance().init(app)

# Register the events
for app_name, app of AppCatalog.catalog
  if app.event_groups?
    for event_group_name of app.event_groups
      event_group = app.event_groups[event_group_name]
      if event_group.namespace? and app.get_instance().event_init?
        console.log "Add Event Namespace: #{event_group.namespace} --> #{app_name}"
        app.get_instance().event_init event_group_name, io.of(event_group.namespace)
      else
        console.warn "Warning: App #{app_name} has malformed event definitions"

# Register app web-api routes
for app_name, app of AppCatalog.catalog
  if app.web_api?
    for api of app.web_api
      if app.web_api[api].router?
        console.log "Add Route: #{app.web_api[api].uri} --> #{app_name}"
        harrogate_app.use app.web_api[api].uri, app.web_api[api].router
      else
        console.warn "Warning: App #{app_name} defines web api '#{api}' but no router"

# Start the apps
for app_name, app of AppCatalog.catalog
  console.log "Starting #{app_name}"
  app.get_instance().exec() if app.get_instance()['exec']?

# Route to static content
harrogate_app.use Express.static(__dirname + '/public')

# Error handling
harrogate_app.use (error, request, response, next) ->
  # Body Parser error
  if error instanceof SyntaxError
    response.writeHead 400, { 'Content-Type': 'application/json' }
    return response.end "#{JSON.stringify(error: 'Malformed syntax, could not parse request')}", 'utf8'

  # harrogate server error
  if error instanceof ServerError
    response.writeHead error.code, { 'Content-Type': 'application/javascript' }
    response.end "#{JSON.stringify(error: error.message)}", 'utf8'
    return

  # Server error?!
  console.error '!!!!INTERNAL SERVER ERROR!!!!'
  console.error error
  console.error 'Stack Trace:'
  console.error error.stack

  response.writeHead 500
  return response.end()

# Start the server
server.listen SettingsManager.settings.server.port, ->
  console.log "\n\n\n\n"
  console.log "*************************************************************"
  console.log "KISS IDE Server started"
  console.log "  Open your browser to 127.0.0.1:#{server.address().port}"
  console.log "  Close this terminal to kill the KISS IDE Server"
  console.log "*************************************************************"

ON_DEATH (signal, err) ->
  console.log "Stopping express.js server"
  server.close()

  # Stop apps
  for app_name, app of AppCatalog.catalog
    console.log "Stopping #{app_name}"
    app.get_instance().closing() if app.get_instance()['closing']
  return
http = require 'http'
url = require 'url'
jade = require 'jade'
json = require 'json'
coffee = require 'coffee-script'
fs = require 'fs'
path_tools = require 'path'
mime = require 'mime'
Cookies = require 'cookies'

public_routes = {}
auth_required_routes = {}

app_catalog = require './shared/scripts/app-catalog.coffee'
public_routes['/json/app-catalog'] = (request, response, cookies) ->
  app_catalog.handle request, response, cookies

app_categories = fs.readFileSync('apps/categories.json', 'utf8')
public_routes['/json/app-categories'] = (request, response) ->
  response.writeHead 200, { 'Content-Type': 'application/json' }
  return response.end app_categories, 'utf8'

err_route = (request, response) ->
  console.log "Failed to serve route #{request.url}"
  response.writeHead 404, {'Content-Type': 'text/plain'}
  response.write 'Page not found'
  response.end()

# Set the route to the index and the login page
index = jade.compile(fs.readFileSync('shared/client/index.jade', 'utf8'), filename: "./shared/client/index.jade")
auth_required_routes['/'] = (request, response) ->
  response.writeHead 200, { 'Content-Type': 'text/html' }
  return response.end index(), 'utf8'

login_instance = require "./shared/scripts/login.coffee"
public_routes['/login'] = (request, response, cookies) ->
  login_instance.handle request, response, cookies

# Parse shared/manifest.json to add routes to shared resources
fs.readFile("shared/manifest.json", 'utf8', (err, data) ->
  return console.log err if err
  
  manifest = JSON.parse data
  return console.log "shared manifest is malformed" if manifest is undefined
  
  return if manifest['resources'] is undefined
  for resource in manifest['resources']
    lam = (r) ->
      parts = r.split ':'
      
      name = parts[0]
      encoding = parts[1]
      
      public_routes["/shared/#{name}"] = (request, response) ->
        fs.readFile("shared/#{name}", encoding, (err, data) ->
          
          return err_route request, response if err
          ext = path_tools.extname name
          if ext is '.coffee'
            response.writeHead 200, {'Content-Type': "application/javascript"}
            return response.end coffee.compile(data), encoding
          
          if ext is '.jade'
            response.writeHead 200, {'Content-Type': "text/html"}
            return response.end jade.compile(data, filename: "#shared#{name}")(), encoding
          
          response.writeHead 200, {'Content-Type': "#{mime.lookup(name)}"}
          response.end data, encoding
        )
    lam resource
)

# Process the app catalog and create the app-related routes
app_instances = {}
for app_name, app of app_catalog.catalog
  app_instances[app_name] = require app['exec_path']
  if app_instances[app_name]['handle']?
    auth_required_routes["#{app['nodejs_route']}"] = app_instances[app_name].handle
  else
    console.log "Warning: #{app['name']} has no handle method"

  # Parse {app}/manifest.json to add routes of app resources
  continue if app['resources'] is undefined
  for resource in app['resources']
    lam = (r) ->
      parts = r.split ':'

      resource_name = parts[0]
      resource_path = "#{app['path']}/#{resource_name}"
      resource_nodejs_route = "#{app['nodejs_route']}/#{resource_name}"
      encoding = parts[1]

      public_routes[resource_nodejs_route] = (request, response) ->
        fs.readFile(resource_path, encoding, (err, data) ->

          return err_route request, response if err
          ext = path_tools.extname resource_name
          if ext is '.coffee'
            response.writeHead 200, {'Content-Type': "application/javascript"}
            return response.end coffee.compile(data), encoding

          if ext is '.jade'
            response.writeHead 200, {'Content-Type': "text/html"}
            return response.end jade.compile(data, filename: resource_path)(), encoding

          response.writeHead 200, {'Content-Type': "#{mime.lookup(resource_name)}"}
          response.end data, encoding
        )
    lam resource

http.createServer((request, response) ->
  cookies = new Cookies(request, response)
  path = url.parse(request.url, true).pathname

  # check if it is a public route
  route = public_routes[path]
  return route(request, response, cookies) if route?

  # check if it is a route who requires authentication
  if auth_required_routes[path]?
    
    # is the user logged in?
    if not login_instance.is_authed(cookies)
      response.statusCode = 302
      response.setHeader("Location", "/login")
      return response.end()

    return auth_required_routes[path](request, response, cookies)

  err_route request, response, cookies

).listen(8888)
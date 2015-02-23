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

app_catalog = {}
app_instances = {}

err_route = (request, response) ->
  console.log "Failed to serve route #{request.url}"
  response.writeHead 404, {'Content-Type': 'text/plain'}
  response.write 'Page not found'
  response.end()

# Set the route to the index and the login page

index = jade.compile(fs.readFileSync('shared/client/index.jade', 'utf8'), filename: "./shared/client/index.jade")
auth_required_routes['/'] = (request, response) ->
  response.writeHead 200, { 'Content-Type': 'text/html' }
  return response.end index(app_catalog_str: JSON.stringify(app_catalog)), 'utf8'

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
            response.writeHead 200, {'Content-Type': "text/javascript"}
            return response.end coffee.compile(data), encoding
          
          if ext is '.jade'
            response.writeHead 200, {'Content-Type': "text/html"}
            return response.end jade.compile(data, filename: "#shared#{name}")(), encoding
          
          response.writeHead 200, {'Content-Type': "#{mime.lookup(name)}"}
          response.end data, encoding
        )
    lam resource
)

# Tell all of the apps about each other
update_app_lists = ->
  for instance in Object.keys app_instances
    app_instances[instance].update_apps(app_catalog) if app_instances[instance]['update_apps']

load_app = (path) ->
  fs.readFile("#{path}/manifest.json", 'utf8', (err, data) ->
    return console.log err if err
    
    manifest = JSON.parse data
    
    return console.log "#{path} manifest is malformed" if manifest is undefined
    
    manifest['priority'] = 0 if manifest['priority'] is undefined
    
    app_catalog[manifest['name']] =
      name: manifest['name']
      priority: manifest['priority']
      url: "/\#/#{path}"
      angular_route: "/#{path}"
      angular_template_path: "/#{path}"
      icon: "/#{path}/#{manifest['icon']}" if manifest['icon']?
      fonticon: manifest['fonticon'] if manifest['fonticon']?
      description: manifest['description']
      category: manifest['category']
      hidden: manifest['hidden']
    
    app_instances[manifest['name']] = require "./#{path}/#{manifest['exec']}"
    
    if !manifest['hidden']
      update_app_lists()
    
    if app_instances[manifest['name']]['handle']?
      auth_required_routes["/#{path}"] = (request, response, cookies) ->
        app_instances[manifest['name']].handle request, response, cookies
    else
      console.log "Warning: #{manifest['name']} has no handle method"
    
    # Parse {app}/manifest.json to add routes to app resources
    return if manifest['resources'] is undefined
    for resource in manifest['resources']
      lam = (r) ->
        parts = r.split ':'
        
        name = parts[0]
        encoding = parts[1]
        
        public_routes["/#{path}/#{name}"] = (request, response) ->
          fs.readFile("#{path}/#{name}", encoding, (err, data) ->
            
            return err_route request, response if err
            ext = path_tools.extname name
            if ext is '.coffee'
              response.writeHead 200, {'Content-Type': "text/javascript"}
              return response.end coffee.compile(data), encoding
            
            if ext is '.jade'
              response.writeHead 200, {'Content-Type': "text/html"}
              return response.end jade.compile(data, filename: "#{path}/#{name}")(), encoding
            
            response.writeHead 200, {'Content-Type': "#{mime.lookup(name)}"}
            response.end data, encoding
          )
      lam resource
  )

fs.readdir('apps', (err, apps) ->
  return console.log err if err
  for app in apps
    continue if !fs.statSync("apps/#{app}").isDirectory()
    load_app "apps/#{app}"
)

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
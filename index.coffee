http = require 'http'
url = require 'url'
jade = require 'jade'
json = require 'json'
coffee = require 'coffee-script'
fs = require 'fs'
path_tools = require 'path'
mime = require 'mime'

requirejs = null
fs.readFile('client/extern/require.js', 'utf8', (err, data) ->
  return console.log err if err
  requirejs = data
)

routes =
  '/': (request, response) ->
    response.statusCode = 302
    response.setHeader("Location", "/apps/home")
    response.end()
  '/extern/require.js': (request, response) ->
    response.writeHead(200, {'Content-Type': 'text/javascript'})
    response.write(requirejs)
    response.end()

app_routes = {}

err_route = (request, response) ->
  console.log "Failed to serve route #{request.url}"
  response.writeHead 404, {'Content-Type': 'text/plain'}
  response.write 'Page not found'
  response.end()

app_catalog = {}
app_instances = {}

# Tell all of the apps about each other
update_app_lists = ->
  for instance in Object.keys app_instances
    app_instances[instance].update_apps(app_catalog) if app_instances[instance]['update_apps']

load_app = (path) ->
  fs.readFile("#{path}/manifest.json", 'utf8', (err, data) ->
    return console.log err if err
    
    manifest = JSON.parse data
    
    return console.log "#{path} manifest is malformed" if manifest is undefined
    
    if !manifest['hidden']
      app_catalog[manifest['name']] =
        name: manifest['name']
        icon: "/#{path}/#{manifest['icon']}" if manifest['icon']?
        fonticon: manifest['fonticon'] if manifest['fonticon']?
        description: manifest['description']
        category: manifest['category']
    
    app_instances[manifest['name']] = require "./#{path}/#{manifest['exec']}"
    
    if !manifest['hidden']
      update_app_lists()
    
    app_routes["#{path_tools.basename(path)}"] = (request, response) ->
      app_instances[manifest['name']].handle request, response
    
    for resource in manifest['resources']
      lam = (r) ->
        parts = r.split ':'
        
        name = parts[0]
        encoding = parts[1]
        
        routes["/#{path}/#{name}"] = (request, response) ->
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
        console.log routes
      lam resource
  )



fs.readdir('apps', (err, apps) ->
  return console.log err if err
  for app in apps
    continue if !fs.statSync("apps/#{app}").isDirectory()
    load_app "apps/#{app}"
)


http.createServer((request, response) ->
  path = url.parse(request.url).pathname.split('?')[0]
  console.log path
  route = routes[path]
  return route request, response if route?
  
  parts = path.split '/'
  if parts[1] is 'apps'
    app_route = app_routes[parts[2]]
    return app_route request, response if app_route?
  
  err_route request, response

).listen(8888)

console.log routes
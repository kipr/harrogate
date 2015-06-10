url = require 'url'
fs = require 'fs'
path = require 'path'

class AppCatalog
  constructor: ->
    @catalog = {}
    @apps_base_path = path.join process.cwd(), 'apps'
    @apps_nodejs_route_base = '/apps'
    @apps_angularjs_route_base = '/apps'

    apps = fs.readdirSync @apps_base_path
    for app in apps
      path = "#{@apps_base_path}/#{app}"
      continue if !fs.statSync(path).isDirectory()

      data = fs.readFileSync "#{path}/manifest.json", 'utf8'
      if not data?
        console.log "Could not read #{path}/manifest.json"
        continue

      manifest = JSON.parse data
      if not manifest?
        console.log "#{path}/manifest.json is malformed"
        continue

      # General app data
      manifest['name'] ?= "#{app}"
      manifest['path'] = "#{path}"
      manifest['description'] ?= ''

      # Bot UI data
      manifest['priority'] ?= 0
      manifest['hidden'] ?= false
      manifest['fonticon'] ?= 'fa-exclamation-triangle'
      manifest['category'] ?= 'General'

      # Server side data ('exec' is set)
      # manifest['init'] nothing to do
      if manifest['exec']?
        manifest['exec_path'] = "#{path}/#{manifest['exec']}"
        manifest['get_instance'] = -> require "#{@exec_path}"
      # manifest['closing'] nothing to do

      # Client side data ('angular_ctrl' is set)
      if manifest['angular_ctrl']?
        manifest['angular_ctrl'] = "#{path}/#{manifest['angular_ctrl']}"
        manifest['url'] = "/##{@apps_angularjs_route_base}/#{app}"
        manifest['angularjs_route'] = "#{@apps_angularjs_route_base}/#{app}"
        manifest['nodejs_route'] = "#{@apps_nodejs_route_base}/#{app}"

      # Client side data (view only)
      else if not manifest['hidden']
        manifest['url'] = "/##{@apps_angularjs_route_base}/#{app}"
        manifest['angularjs_route'] = "#{@apps_angularjs_route_base}/#{app}"
        manifest['nodejs_route'] = "#{@apps_nodejs_route_base}/#{app}"

      # Web API data
      # manifest['web_api'] nothing to do

      @catalog[manifest['name']] = manifest

  handle: (request, response) ->
    callback = url.parse(request.url, true).query['callback']
    # should we return JSON or JSONP (callback defined)?
    if callback?
      response.writeHead 200, { 'Content-Type': 'application/javascript' }
      return response.end "#{callback}(#{JSON.stringify(@catalog)})", 'utf8'
    else
      response.writeHead 200, { 'Content-Type': 'application/json' }
      return response.end "#{JSON.stringify(@catalog)}", 'utf8'

module.exports = new AppCatalog
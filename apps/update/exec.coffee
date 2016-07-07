Express = require 'express'
Fs = require 'fs'
Os = require 'os'
Path = require 'path'
exec = require('child_process').exec
spawn = require('child_process').spawn

AppCatalog = require_harrogate_module '/shared/scripts/app-catalog.js'
ServerError = require_harrogate_module '/shared/scripts/server-error.js'
events = AppCatalog.catalog['Update'].event_groups.update_events.events

# update can only run once
is_updating = false

socket = undefined
update_on_connection = (s) ->
  if socket?
    socket.disconnect()
  socket = s

# the fs router
router = Express.Router()

router.get '/', (request, response, next) ->
  if is_updating
     next new ServerError(405, 'Update already in progress')
     return

  if Os.platform() is 'win32' or Os.platform() is 'darwin'
    next new ServerError(503, 'This plattform does not support update')
    return

  # mount the fs
  process = exec 'mount /dev/sda1 /mnt', (error, stdout, stderr) ->
  # process = exec 'ls', (error, stdout, stderr) ->
    if socket?
      socket.emit events.stdout.id, stdout
      socket.emit events.stderr.id, stderr
    
    if error?
      next new ServerError(405, "Could not list the mount the USB drive: #{error}")
      return

    # list the files
    src_path = '/mnt'
    # src_path = '/home/stefan/usb'

    Fs.readdir src_path, (error, files) ->
      if error?
        next new ServerError(405, "Could not list the files: #{error}")
        return

      scripts = []

      for file in files
        file = Path.resolve src_path, file
        file_stats = Fs.statSync file
        if file_stats? and file_stats.isDirectory()
          for f in Fs.readdirSync file
            if f.indexOf('.sh') isnt -1
              scripts.push Path.resolve(file, f)
        else if file.indexOf('.sh') isnt -1
          scripts.push Path.resolve(src_path, file)

      response.setHeader 'Cache-Control', 'no-cache, no-store, must-revalidate'
      response.setHeader 'Pragma', 'no-cache'
      response.setHeader 'Expires', '0'
      response.writeHead 200, { 'Content-Type': 'application/json' }
      response.end "#{JSON.stringify(scripts)}", 'utf8'

router.post '/', (request, response, next) ->
  if is_updating
     next new ServerError(405, 'Update already in progress')
     return

  if Os.platform() is 'win32' or Os.platform() is 'darwin'
    next new ServerError(503, 'This plattform does not support update')
    return

  # Validate the script
  if not request.body.script?
    next new ServerError(422, 'Parameter \'script\' missing')
    return

  # run the update script
  is_updating = true
  script = Path.join harrogate_base_path, 'update_wallaby.sh'
  process = spawn script, [request.body.script]
  
  process.stdout.on 'data', (data) ->
    socket.emit events.stdout.id, data.toString('utf8')
  
  process.stderr.on 'data', (data) ->
    socket.emit events.stderr.id, data.toString('utf8')

  process.on 'error', (data) ->
    socket.emit events.stderr.id, data.toString('utf8')

  process.on 'exit', (code) ->
    is_updating = false
    socket.emit events.stdout.id, "Script exited with code #{code}"

    response.setHeader 'Cache-Control', 'no-cache, no-store, must-revalidate'
    response.setHeader 'Pragma', 'no-cache'
    response.setHeader 'Expires', '0'
    response.writeHead 204, { 'Content-Type': 'application/json' }
    return response.end

module.exports =
  init: (app) ->
    app.web_api.update['router'] = router
    return

  event_init: (event_group_name, namespace) ->
    namespace.on 'connection', update_on_connection
    return

  exec: ->
    return

Express = require 'express'
Fs = require 'fs'
Os = require 'os'
Path = require 'path'
exec = require('child_process').exec
spawn = require('child_process').spawn

AppCatalog = require_harrogate_module '/shared/scripts/app-catalog.coffee'
ServerError = require_harrogate_module '/shared/scripts/server-error.coffee'
events = AppCatalog.catalog['Upgrade'].event_groups.upgrade_events.events

# upgrade can only run once
is_upgrading = false

socket = undefined
upgrade_on_connection = (s) ->
  if socket?
    socket.disconnect()
  socket = s

# the fs router
router = Express.Router()

router.get '/', (request, response, next) ->
  if is_upgrading
     next new ServerError(405, 'Upgrade already in progress')
     return

  if Os.platform() is 'win32' or Os.platform() is 'darwin'
    next new ServerError(503, 'This plattform does not support upgrade')
    return

  # mount the fs
  process = exec 'mount /dev/sda1 /mnt', (error, stdout, stderr) ->
  # process = exec 'ls', (error, stdout, stderr) ->
    if socket?
      socket.emit events.stdout.id, stdout
      socket.emit events.stderr.id, stderr
    
    if error?
      next new ServerError(405, "Could not mount the USB drive: #{error}")
      return

    # list the files
    src_path = '/mnt'
    # src_path = '/home/stefan/usb'

    Fs.readdir src_path , (error, files) ->
      if error?
        next new ServerError(405, "Could not list the files: #{error}")
        return

      scripts = []

      for file in files
        file = Path.resolve src_path, file
        file_stats = Fs.statSync file
        if file_stats? and file_stats.isDirectory()
          for f in Fs.readdirSync file
            if f.indexOf('tar.bz2') isnt -1
              scripts.push Path.resolve(file, f)
        else if file.indexOf('tar.bz2') isnt -1
          scripts.push Path.resolve(src_path, file)

      response.setHeader 'Cache-Control', 'no-cache, no-store, must-revalidate'
      response.setHeader 'Pragma', 'no-cache'
      response.setHeader 'Expires', '0'
      response.writeHead 200, { 'Content-Type': 'application/json' }
      return response.end "#{JSON.stringify(scripts)}", 'utf8'

router.post '/', (request, response, next) ->
  if is_upgrading
     next new ServerError(405, 'Upgrade already in progress')
     return

  if Os.platform() is 'win32' or Os.platform() is 'darwin'
    next new ServerError(503, 'This plattform does not support upgrade')
    return

  # Validate the script
  if not request.body.script?
    next new ServerError(422, 'Parameter \'script\' missing')
    return

  # run the upgrade script
  is_upgrading = true
  script = Path.join harrogate_base_path, 'upgrade_wallaby.sh'
  process = spawn script, [request.body.script]
  
  process.stdout.on 'data', (data) ->
    socket.emit events.stdout.id, data.toString('utf8')
  
  process.stderr.on 'data', (data) ->
    socket.emit events.stderr.id, data.toString('utf8')

  process.on 'error', (data) ->
    socket.emit events.stderr.id, data.toString('utf8')

  process.on 'exit', (code) ->
    is_upgrading = false
    socket.emit events.stdout.id, "Script exited with code #{code}"

    response.setHeader 'Cache-Control', 'no-cache, no-store, must-revalidate'
    response.setHeader 'Pragma', 'no-cache'
    response.setHeader 'Expires', '0'
    response.writeHead 204, { 'Content-Type': 'application/json' }
    response.end

module.exports =
  init: (app) ->
    app.web_api.upgrade['router'] = router
    return

  event_init: (event_group_name, namespace) ->
    namespace.on 'connection', upgrade_on_connection
    return

  exec: ->
    return

Os = require 'os'
Path = require 'path'
spawn = require('child_process').spawn

AppCatalog = require_harrogate_module '/shared/scripts/app-catalog.coffee'

events = AppCatalog.catalog['Upgrade'].event_groups.upgrade_events.events

if Os.platform() is 'win32'
  pre_upgrade_cmd = undefined
  upgrade_cmd = undefined
else if Os.platform() is 'darwin'
  pre_upgrade_cmd = undefined
  upgrade_cmd = undefined
else # Linux
  
  pre_upgrade_cmd = Path.resolve Path.join(harrogate_base_path, 
  upgrade_cmd = undefined


create_upgrade_cmd = (socket, upgrade_cmd) ->
  if upgrade_cmd?
    process = spawn upgrade_cmd

    process.stdout.on 'data', (data) ->
      socket.emit events.stdout.id, data.toString('utf8')
      return

    process.stderr.on 'data', (data) ->
      socket.emit events.stderr.id, data.toString('utf8')
      return

    process.on 'exit', (code) ->
      socket.disconnect()
      return

    return process
  return undefined


upgrade_on_connection = (socket) ->
  process = create_upgrade_cmd socket

  socket.on events.stdin.id, (data) ->
    process.stdin.write data + '\n'
    return

  socket.on events.restart.id, (data) ->
    process = create_upgrade_cmd socket
    return

  return

module.exports =
  event_init: (event_group_name, namespace) ->
    namespace.on 'connection', upgrade_on_connection
    return

  exec: ->
    return

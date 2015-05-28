spawn = require('child_process').spawn

AppCatalog = require '../../shared/scripts/app-catalog.coffee'
TargetApp = AppCatalog.catalog['Target information'].get_instance()

events = AppCatalog.catalog['Terminal'].event_groups.terminal_events.events

terminal_emulator = undefined
if TargetApp.platform is TargetApp.supported_platforms.WINDOWS_PC
  terminal_emulator = 'cmd'

create_terminal_emulator = (socket) ->
  if terminal_emulator?
    process = spawn terminal_emulator
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

module.exports =
  terminal_on_connection: (socket) ->
    process = create_terminal_emulator socket

    socket.on events.stdin.id, (data) ->
      process.stdin.write data + '\n'
      return

    socket.on events.restart.id, (data) ->
      process = create_terminal_emulator socket
      return

    return

  exec: ->
    return
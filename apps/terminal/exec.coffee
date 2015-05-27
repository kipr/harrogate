spawn = require('child_process').spawn
WebSocketServer = require('ws').Server

AppCatalog = require '../../shared/scripts/app-catalog.coffee'
TargetApp = AppCatalog.catalog['Target information'].get_instance()

wss = undefined

terminal_emulator = undefined
if TargetApp.platform is TargetApp.supported_platforms.WINDOWS_PC
  terminal_emulator = 'cmd'

module.exports =
  exec: ->
    wss_port = AppCatalog.catalog['Terminal'].config.terminal_wss_port
    console.log "Starting terminal web socket server at port #{wss_port}"
    wss = new WebSocketServer(port: wss_port)

    wss.on 'connection', (ws) ->

      if terminal_emulator?
        process = spawn terminal_emulator
        process.stdout.on 'data', (data) ->
          ws.send data.toString('utf8')
          return
        process.stderr.on 'data', (data) ->
          ws.send data.toString('utf8')
          return
        process.on 'exit', (code) ->
          ws.close()
          return

        ws.on 'message', (data, flags) ->
          process.stdin.write data + '\n'
          return

      return

  closing: ->
    wss.close() if wss?
    wss = undefined
    return
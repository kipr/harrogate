spawn = require('child_process').spawn

class Program
  constructor: ->
    @listeners = []
    
  start: (path, args) ->
    @running = spawn(path, args)
    
    @running.stdout.on 'data', (data) ->
      listener.stdout data for listener in @listeners
    @running.stderr.on 'data', (data) ->
      listener.stdout data for listener in @listeners
  
  register_listener: (listener) ->
    @listeners.push listener
    
  
module.exports = new Program
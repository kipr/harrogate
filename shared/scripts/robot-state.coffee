daylite = require_harrogate_module '/shared/scripts/daylite.coffee'

state = undefined

if daylite
  daylite.subscribe '/test', (msg) -> state = msg
    
module.exports = () -> state
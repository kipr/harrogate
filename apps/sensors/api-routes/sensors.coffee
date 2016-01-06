Express = require 'express'
Url = require 'url'

rs = require_harrogate_module '/shared/scripts/robot-state.coffee'

# the fs router
router = Express.Router()

console.log "Loaded sensor API route"

router.get '/', (request, response, next) ->
  response.setHeader 'Cache-Control', 'no-cache, no-store, must-revalidate'
  response.setHeader 'Pragma', 'no-cache'
  response.setHeader 'Expires', '0'
  response.writeHead 200, { 'Content-Type': 'application/json' }
  
  state = rs()
  if not state
    return response.end "#{JSON.stringify({})}", 'utf8'
  msg =
    analogs: state.analog_state
    digitals: state.digital_state
    battery: state.battery_state
    imu: state.imu_state
  response.end "#{JSON.stringify(msg)}", 'utf8'
  return

# export the router object
module.exports = router
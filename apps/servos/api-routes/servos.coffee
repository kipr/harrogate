Express = require 'express'
Url = require 'url'

rs = require_harrogate_module '/shared/scripts/robot-state.coffee'

# the fs router
router = Express.Router()

router.get '/', (request, response, next) ->
  response.setHeader 'Cache-Control', 'no-cache, no-store, must-revalidate'
  response.setHeader 'Pragma', 'no-cache'
  response.setHeader 'Expires', '0'
  response.writeHead 200, { 'Content-Type': 'application/json' }
  
  state = rs()
  if not state
    return response.end "#{JSON.stringify({})}", 'utf8'
  msg =
    servos: state.servo_states
  response.end "#{JSON.stringify(msg)}", 'utf8'
  return

router.post '/', (request, response, next) ->
  # We only support application/json
  if not /application\/json/i.test request.headers['content-type']
    next new ServerError(415, 'Only content-type application/json supported')
    return

  if daylite?
    daylite.publish 'robot/set_servo_state', request.body
    response.writeHead 201
    response.end()
  else
    response.writeHead 503
    response.end()

module.exports = router
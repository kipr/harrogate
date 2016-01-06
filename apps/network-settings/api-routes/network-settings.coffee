Express = require 'express'

# the fs router
router = Express.Router()

# '/' is relative to <manifest>.web_api.settings.uri
router.get '/', (request, response, next) ->

  # TODO: Add wifi settings daylite node here

  response.setHeader 'Cache-Control', 'no-cache, no-store, must-revalidate'
  response.setHeader 'Pragma', 'no-cache'
  response.setHeader 'Expires', '0'
  response.writeHead 204, { 'Content-Type': 'application/json' }
  return response.end "", 'utf8'

module.exports = router
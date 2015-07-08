exports.inject = (app) ->
  # inject runner angular modules
  require('./program-service.coffee').inject app
  require('./runner-view-controller.coffee').inject app
  return

# view controller
exports.controller = require('./runner-view-controller.coffee').controller

# view controller
exports.services =
[
  require('./program-service.coffee').service
]
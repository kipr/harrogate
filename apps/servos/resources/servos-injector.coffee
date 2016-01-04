exports.inject = (app) ->
  # inject servos angular modules
  require('./servos-view-controller.coffee').inject app
  return

# view controller
exports.controller = require('./servos-view-controller.coffee').controller
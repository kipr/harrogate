exports.inject = (app) ->
  # inject sensors angular modules
  require('./sensors-view-controller.coffee').inject app
  return

# view controller
exports.controller = require('./sensors-view-controller.coffee').controller
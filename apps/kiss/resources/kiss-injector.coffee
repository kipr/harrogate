exports.inject = (app) ->
  # inject kiss angular modules
  require('./kiss-view-controller.coffee').inject app
  return

# view controller
exports.controller = require('./kiss-view-controller.coffee').controller
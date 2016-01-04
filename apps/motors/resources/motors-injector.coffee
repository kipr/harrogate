exports.inject = (app) ->
  # inject motors angular modules
  require('./motors-view-controller.coffee').inject app
  return

# view controller
exports.controller = require('./motors-view-controller.coffee').controller
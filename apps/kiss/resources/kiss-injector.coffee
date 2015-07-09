exports.inject = (app) ->
  # inject kiss angular modules
  require('./discard-change-modal-controller.coffee').inject app
  require('./kiss-view-controller.coffee').inject app
  return

# view controller
exports.controller = require('./kiss-view-controller.coffee').controller
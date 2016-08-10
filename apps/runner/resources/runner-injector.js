exports.inject = function(app) {
  // inject runner angular modules
  require('./program-service.js').inject(app);
  require('./runner-view-controller.js').inject(app);
};

// view controller
exports.controller = require('./runner-view-controller.js').controller;

// view controller
exports.services = [require('./program-service.js').service];

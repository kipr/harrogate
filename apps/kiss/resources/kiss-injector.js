exports.inject = function(app) {
  // inject kiss angular modules
  require('./kiss-view-controller.js').inject(app);
};

// view controller
exports.controller = require('./kiss-view-controller.js').controller;

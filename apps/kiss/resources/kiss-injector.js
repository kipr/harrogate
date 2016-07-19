exports.inject = function(app) {
  // inject kiss angular modules
  require('./kiss-view-controller.coffee').inject(app);
};

// view controller
exports.controller = require('./kiss-view-controller.coffee').controller;

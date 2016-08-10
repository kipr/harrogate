exports.name = 'HarrogateFsInjector';

exports.inject = function(app) {
  // inject fs angular modules
  require('./fs-view-controller.js').inject(app);
};

// view controller
exports.controller = require('./fs-view-controller.js').controller;

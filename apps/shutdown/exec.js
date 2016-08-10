module.exports = {
  init: (function(_this) {
    return function(app) {
      // add the router
      app.web_api.shutdown['router'] = require('./api-routes/shutdown.js');
    };
  })(this),
  exec: function() {}
};

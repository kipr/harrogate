module.exports = {
  init: (function(_this) {
    return function(app) {
      // add the router
      app.web_api.about['router'] = require('./api-routes/about.js');
    };
  })(this),
  exec: function() {}
};

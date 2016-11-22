
module.exports = {
  init: (function(_this) {
    return function(app) {
      // add the router
      app.web_api.settings['router'] = require('./api-routes/settings.js');
      app.web_api.workspace['router'] = require('./api-routes/workspace.js');
    };
  })(this),
  exec: function() {}
};

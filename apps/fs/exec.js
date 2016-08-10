module.exports = {
  init: function(app) {
    return app.web_api.fs['router'] = require('./api-routes/fs.js');
  },
  exec: function() {}
};

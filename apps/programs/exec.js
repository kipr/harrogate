module.exports = {
  init: function(app) {
    return app.web_api.projects['router'] = require('./api-routes/projects.js');
  },
  exec: function() {}
};

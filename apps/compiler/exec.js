module.exports = {
  init: function(app) {
    app.web_api.run['router'] = require('./api-routes/compile.js');
  },
  exec: function() {}
};

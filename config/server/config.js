var _ = require('lodash');

module.exports = _.extend(
  {
    port: process.env.PORT || 8888
  },
  require('./env/' + process.env.NODE_ENV + '.json') || {}
);

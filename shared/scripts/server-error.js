var ServerError,
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

ServerError = (function(superClass) {
  extend(ServerError, superClass);

  function ServerError(code, message) {
    this.code = code;
    this.message = message;
    Error.captureStackTrace(this, this);
  }

  return ServerError;

})(Error);

module.exports = ServerError;

class ServerError extends Error
  constructor: (@code, @message) -> 
    Error.captureStackTrace(@,@)

module.exports = ServerError
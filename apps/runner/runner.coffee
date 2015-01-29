module.exports =
  handle: (request, response) ->
    response.writeHead 200, { 'Content-Type': 'text/plain' }
    response.end 'Hello there\n'
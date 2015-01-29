jade = require 'jade'
fs = require 'fs'
url = require 'url'
path_tools = require 'path'
qs = require 'querystring'

index = jade.compile(fs.readFileSync('apps/login/index.jade', 'utf8'), filename: "./apps/login/index.jade")

the_password = 'test'

handle_auth = (request, response, cookies) ->
  body = ''
  request.on 'data', (data) ->
    body += data
    if body.length > 128
      request.connection.destroy()
  request.on 'end', ->
    post = qs.parse body
    response.statusCode = 302
    console.log post['password']
    if post['password'] isnt the_password
      response.setHeader("Location", "/apps/login?retry=true")
    else
      console.log "success"
      cookies.set 'session', 'signed_in'
      response.setHeader("Location", "/apps/home")
    response.end()
    
authed = (cookies) ->
  session = cookies.get 'session'
  session is 'signed_in'
    
module.exports =
  is_authed: authed
  handle: (request, response, cookies) ->
    if authed(cookies)
      response.statusCode = 302
      response.setHeader("Location", "/apps/home")
      return response.end()
    u = url.parse(request.url, true)
    if u.pathname isnt '/apps/login'
      response.writeHead 404, { 'Content-Type': 'text/plain' }
      return response.end 'Page not found\n'
    return handle_auth(request, response, cookies) if request.method is 'POST'
    
    response.writeHead 200, { 'Content-Type': 'text/html' }
    return response.end index(retry: u.query['retry']), 'utf8'
    
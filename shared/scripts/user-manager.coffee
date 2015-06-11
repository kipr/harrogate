assert = require 'assert'
Fs = require 'fs'
Path = require 'path'
_ = require 'lodash'

User = require './user.coffee'

class UserManager
  constructor: ->
    @users_file_paht = Path.join process.cwd(), 'users.json'

    try
      @users = require @users_file_paht
    catch
      @users = {}

  update_user: (user) =>
    assert(user instanceof User)
    assert(user.login?)

    @users =  _.merge(@users[user.login], user)
    Fs.writeFile @users_file_paht, JSON.stringify(@users, null, 2), 'utf8'
    return

  add_user: (user) =>
    assert(user instanceof User)
    assert(user.login?)

    @users[user.login] = user
    Fs.writeFile @users_file_paht, JSON.stringify(@users, null, 2), 'utf8'
    return

module.exports = new UserManager

assert = require 'assert'
Fs = require 'fs'
Path = require 'path'
_ = require 'lodash'

User = require './user.coffee'

sys_app_data_path = process.env.APPDATA || (process.platform == 'darwin' ? process.env.HOME + 'Library/Preference' : '/var/local')
harrogate_app_data_path = Path.join sys_app_data_path, 'KIPR Software Suite'
try
  Fs.mkdirSync harrogate_app_data_path

class UserManager
  constructor: ->
    @users_file_paht = Path.join harrogate_app_data_path, 'users.json'

    console.log 'User settings file path: ' + @users_file_paht

    try
      @users = require @users_file_paht
    catch
      @users = {}

  update_user: (login, data) =>
    assert(@users[login]?)

    @users[login] =  _.merge(@users[login], data)
    Fs.writeFile @users_file_paht, JSON.stringify(@users, null, 2), 'utf8'
    return

  add_user: (user) =>
    assert(user instanceof User)
    assert(user.login?)

    @users[user.login] = user
    Fs.writeFile @users_file_paht, JSON.stringify(@users, null, 2), 'utf8'
    return

module.exports = new UserManager

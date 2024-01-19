var Fs, Path, User, UserManager, _, assert, harrogate_app_data_path, sys_app_data_path,
  bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

assert = require('assert');

Fs = require('fs');

Path = require('path');

_ = require('lodash');

User = require('./user.js');

sys_app_data_path = (process.platform === 'darwin' ? Path.join(process.env.HOME, 'Library/Preferences') : '/var/local') || process.env.APPDATA;

harrogate_app_data_path = Path.join(sys_app_data_path, 'KIPR Software Suite');

// TODO: Make this automatically create the directory if it doesn't exist
// Issue: Permission denied on Wombat when accessing /var/local
// try {
//   Fs.mkdirSync(harrogate_app_data_path);
// } catch (undefined) {
//   console.log('could not create harrogate app data path');
// }

UserManager = (function() {
  function UserManager() {
    this.add_user = bind(this.add_user, this);
    this.update_user = bind(this.update_user, this);
    this.list_users = bind(this.list_users, this);
    var error;
    this.users_file_path = Path.join(harrogate_app_data_path, 'users.json');
    console.log('User settings file path: ' + this.users_file_path);
    try {
      this.users = require(this.users_file_path);
    } catch (error) {
      this.users = {};
    }
  }

  UserManager.prototype.update_user = function(login, data) {
    assert(this.users[login] != null);
    this.users[login] = _.merge(this.users[login], data);
    Fs.writeFile(this.users_file_path, JSON.stringify(this.users, null, 2), 'utf8', (err) => {if (err) throw err;});
  };

  UserManager.prototype.add_user = function(user) {
    assert(user instanceof User);
    assert(user.login != null);
    this.users[user.login] = user;
    Fs.writeFile(this.users_file_path, JSON.stringify(this.users, null, 2), 'utf8', (err) => {if (err) throw err;});
  };

  return UserManager;

})();

module.exports = new UserManager;

var AppCatalog, Path, TargetApp, User;

Path = require('path');

AppCatalog = require_harrogate_module('/shared/scripts/app-catalog.js');

TargetApp = AppCatalog.catalog['Target information'].get_instance();

User = (function() {
  function User(login) {
    this.login = login;
    this.preferences = {};
    this.preferences.workspace = {};
    // set default workspace
    if (TargetApp.platform === TargetApp.supported_platforms.WINDOWS_PC) {
      this.preferences.workspace.path = Path.join(process.env['USERPROFILE'], 'Documents', 'KISS');
    } else {
      this.preferences.workspace.path = Path.join(process.env['HOME'], 'Documents', 'KISS');
    }
  }

  return User;

})();

module.exports = User;

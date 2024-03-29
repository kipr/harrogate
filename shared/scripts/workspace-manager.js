var Fs, Path, User, UserManager, _, assert, harrogate_app_data_path, sys_app_data_path,
  bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

assert = require('assert');

Fs = require('fs');

Path = require('path');

_ = require('lodash');

const AppCatalog = require_harrogate_module('/shared/scripts/app-catalog.js');
const TargetApp = AppCatalog.catalog['Target information'].get_instance();

User = require('./user.js');

sys_app_data_path = (process.platform === 'darwin' ? Path.join(process.env.HOME, 'Library/Preferences') : '/var/local') || process.env.APPDATA;

harrogate_app_data_path = Path.join(sys_app_data_path, 'KIPR Software Suite');

// TODO: Make this automatically create the directory if it doesn't exist
// Issue: Permission denied on Wombat when accessing /var/local
// try {
//   console.log('harrogate_app_data_path: ' + harrogate_app_data_path);
//   Fs.mkdirSync(harrogate_app_data_path);
// } catch (undefined) {
//   console.log('could not create harrogate app data path');
// }

WorkspaceManager = (function() {
  function WorkspaceManager() {

    this.set_workspace_path = bind(this.set_workspace_path, this);
    this.get_workspace_path = bind(this.get_workspace_path, this);
    var error;
    this.workspace_file_path = Path.join(harrogate_app_data_path, 'workspace.json');
    console.log('workspace file path: ' + this.workspace_file_path);
    try {
      this.workspace_path = require(this.workspace_file_path);
    } catch (error) {
      if (TargetApp.platform === TargetApp.supported_platforms.WINDOWS_PC) {
        this.workspace_path = Path.join(process.env['USERPROFILE'], 'Documents', 'KISS');
      } else {
        this.workspace_path = Path.join(process.env['HOME'], 'Documents', 'KISS');
      }
      
      this.update_workspace_path(this.workspace_path);
    }
  }

  WorkspaceManager.prototype.update_workspace_path = function(path) {
    this.workspace_path = path;
    Fs.writeFile(this.workspace_file_path,
		 JSON.stringify(this.workspace_path, null, 2),
		 'utf8', (err) => {if (err) throw err;}
	);
 };

  return WorkspaceManager;
})();

module.exports = new WorkspaceManager;

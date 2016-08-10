var Fs, Path, SettingsManager, _,
  bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

Fs = require('fs');

Path = require('path');

_ = require('lodash');

SettingsManager = (function() {
  function SettingsManager() {
    this.reset_to_platform_default = bind(this.reset_to_platform_default, this);
    this.set = bind(this.set, this);
    this.update = bind(this.update, this);
    this.settings_file_paht = Path.join(process.cwd(), 'settings.json');
    this.settings = require(this.settings_file_paht);
  }

  SettingsManager.prototype.update = function(value) {
    this.settings = _.merge(this.settings, value);
    Fs.writeFile(this.settings_file_paht, JSON.stringify(this.settings, null, 2), 'utf8');
  };

  SettingsManager.prototype.set = function(value) {
    this.settings = value;
    Fs.writeFile(this.settings_file_paht, JSON.stringify(this.settings, null, 2), 'utf8');
  };

  SettingsManager.prototype.reset_to_platform_default = function() {
    var settings;
    settings = {};

    // Server settings
    settings.server = {
      port: 8888
    };
    this.set(settings);
  };

  return SettingsManager;

})();

module.exports = new SettingsManager;

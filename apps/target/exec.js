var Os, TargetInformation;

Os = require('os');

TargetInformation = (function() {
  function TargetInformation() {
    this.supported_platforms = {
      LINK: 0,
      LINK2: 1,
      WINDOWS_PC: 2,
      MAC: 3
    };
    this.platform = void 0;
    this.supported_os = {
      LINUX: 0,
      WINDOWS: 1,
      OSX: 2
    };
    this.os = void 0;
    switch (Os.platform()) {
      case 'win32':
        this.platform = this.supported_platforms.WINDOWS_PC;
        this.os = this.supported_os.WINDOWS;
        break;
      case 'darwin':
        this.platform = this.supported_platforms.MAC;
        this.os = this.supported_os.OSX;
      // TODO: Add info for Link?/Link2
    }
  }

  // Add the target information
  TargetInformation.prototype.init = function(app) {
    app['supported_platforms'] = this.supported_platforms;
    app['platform'] = this.platform;
    app['supported_os'] = this.supported_os;
    app['os'] = this.os;
  };

  return TargetInformation;

})();

module.exports = new TargetInformation;

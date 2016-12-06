var Fs, Os, Path, config, version;

Fs = require('fs');

Os = require('os');

Path = require('path');

version = require('./package.json').version.split('.');

config = {
  version: {
    major: version[0],
    minor: version[1],
    build_number: version[3]
  }
};

// Botball board firmware version
if (Os.platform() === 'linux') {
  try {
    version = Fs.readFileSync('/usr/share/kipr/board_fw_version.txt', 'utf8');
    config.botball_fw_version = version;
  } catch (undefined) {}
}

if (Os.platform() === 'win32') {
  config.ext_deps = {
    include_path: Path.join(__dirname, '..', 'shared', 'include'),
    lib_path: Path.join(__dirname, '..', 'shared', 'lib'),
    bin_path: Path.join(__dirname, '..', 'shared', 'bin'),
    min_gw: {
      bin_path: Path.join(__dirname, '..', 'MinGW', 'bin')
    }
  };
} else {
  config.ext_deps = {
    include_path: Path.join('/usr', 'local', 'include', 'include'),
    lib_path: Path.join('/usr', 'local', 'lib'),
    bin_path: Path.join('/usr', 'local', 'bin')
  };
}

module.exports = config;

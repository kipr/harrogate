Os = require 'os'
Path = require 'path'

version = require('./package.json').version.split '.'

config =
  version:
    major: version[0]
    minor: version[1]
    build_number: version[2]

if Os.platform() is 'win32'
  config. ext_deps =
    include_path: Path.join __dirname, '..', 'shared', 'include'
    lib_path:  Path.join __dirname, '..', 'shared', 'lib'
    bin_path:  Path.join __dirname, '..', 'shared', 'bin'

    min_gw:
      bin_path: Path.join __dirname, '..', 'MinGW', 'bin'
else
  config.ext_deps =
    include_path: Path.join '/usr', 'local', 'include', 'include'
    lib_path:  Path.join '/usr', 'local', 'lib'
    bin_path:  Path.join '/usr', 'local', 'bin'

module.exports = config

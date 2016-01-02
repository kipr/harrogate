Path = require 'path'

version = require('./package.json').version.split '.'

module.exports =
  version:
    major: version[0]
    minor: version[1]
    build_number: version[2]

  ext_deps:
    include_path: Path.join __dirname, '..', 'shared', 'include'
    lib_path:  Path.join __dirname, '..', 'shared', 'lib'
    bin_path:  Path.join __dirname, '..', 'shared', 'bin'

    min_gw:
      bin_path: Path.join __dirname, '..', 'MinGW', 'bin'
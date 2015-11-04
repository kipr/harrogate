﻿Path = require 'path'

module.exports =
  version:
    major: 1
    minor: 1
    build_number: 4

  ext_deps:
    include_path: Path.join __dirname, '..', 'shared', 'include'
    lib_path:  Path.join __dirname, '..', 'shared', 'lib'
    bin_path:  Path.join __dirname, '..', 'shared', 'bin'

    min_gw:
      bin_path: Path.join __dirname, '..', 'MinGW', 'bin'
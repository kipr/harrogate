require 'codemirror/mode/clike/clike'
code_mirror = require 'codemirror/lib/codemirror'

exports.name = 'kiss_view_controller'

exports.inject = (app) ->
  app.controller exports.name, ['$scope', '$location', '$http', exports.controller]
  exports.controller

exports.controller = ($scope, $location, $http) ->
  document.getElementById('editor')
  editor = code_mirror.fromTextArea(document.getElementById('editor'),
    mode: 'text/x-csrc'
    lineNumbers: true
    theme : 'eclipse'
  )

  # do we have to open a file?
  if $location.search().path?
    file_uri = $location.search().path
    $http.get(file_uri)
    .success (data, status, headers, config) ->
      editor.setValue(new Buffer(data.content, 'base64').toString('ascii'));
      return
    .error (data, status, headers, config) ->
      console.log "Could not get #{web_api.rel_uri}"
      return
  return
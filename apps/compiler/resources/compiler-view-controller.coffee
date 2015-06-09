code_mirror = require 'codemirror/lib/codemirror'
io = require 'socket.io-client'

exports.name = 'compiler_view_controller'

exports.inject = (app) ->
  app.controller exports.name, [
    '$scope'
    '$http'
    'app_catalog_provider'
    exports.controller
  ]
  exports.controller

exports.controller = ($scope, $http, app_catalog_provider) ->
  socket = undefined
  events = undefined
  editor = undefined

  editor = code_mirror.fromTextArea(document.getElementById('output'),
    lineNumbers: false
    theme: 'eclipse'
  )

  app_catalog_provider.catalog.then (app_catalog) ->
    projects_resource = app_catalog['Programs']?.web_api?.projects
    if projects_resource?
      $http.get(projects_resource.uri)
      .success (data, status, headers, config) ->
        $scope.ws = data
        return
      .error (data, status, headers, config) ->
        console.log "Could not get #{uri}"
        return
    return

  $scope.select_project = (project) ->
    # toggle selection
    if $scope.selected_project is project
      $scope.selected_project = null
    else
      $scope.selected_project = project
    return

  append_text = (text) ->
    if editor?
      editor.replaceRange text, code_mirror.Pos(editor.lastLine())
      editor.setCursor editor.lineCount(), 0
    return

  return
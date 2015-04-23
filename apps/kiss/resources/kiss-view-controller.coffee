require 'codemirror/mode/clike/clike'
code_mirror = require 'codemirror/lib/codemirror'

exports.name = 'kiss_view_controller'

exports.inject = (app) ->
  app.controller exports.name, ['$scope', '$location', '$http', 'app_catalog_provider', exports.controller]
  exports.controller

exports.controller = ($scope, $location, $http, app_catalog_provider) ->
  open_file = (file_uri) ->
    $scope.displayed_file = undefined

    $http.get(file_uri)
    .success (data, status, headers, config) ->
      $scope.displayed_file = data
      editor.setValue(new Buffer($scope.displayed_file.content, 'base64').toString('ascii'));
      return
    .error (data, status, headers, config) ->
      console.log "Could not get #{file_uri}"
      return

  document.getElementById('editor')
  editor = code_mirror.fromTextArea(document.getElementById('editor'),
    mode: 'text/x-csrc'
    lineNumbers: true
    theme : 'eclipse'
  )

  # do we have to open a file?
  if $location.search().path?
    file_uri = $location.search().path
    open_file file_uri

  app_catalog_provider.catalog.then (app_catalog) ->
    fs_api = app_catalog['Programs']?.web_api?.projects
    if fs_api?
      $http.get(fs_api.uri)
      .success (data, status, headers, config) ->
        $scope.ws = data
        return
      .error (data, status, headers, config) ->
        console.log "Could not get #{uri}"
        return
    return

  $scope.select_project = (project) ->
    $scope.selected_project = project
    $scope.selected_file = undefined

    # load project files
    $http.get(project.links.self.href)
    .success (data, status, headers, config) ->
      $scope.project_files = data.files
      return
    .error (data, status, headers, config) ->
      console.log "Could not get #{project.links.self.href}"
      return
    return

  $scope.select_file = (file) ->
    $scope.selected_file = file
    open_file $scope.selected_file.links.self.href
    return

  $scope.save = ->
    if $scope.displayed_file?
      content = editor.getValue()
      content = new Buffer(content).toString('base64')

      $http.put($scope.displayed_file.links.self.href, { content: content, encoding: 'ascii' })
      .success (data, status, headers, config) ->
        alert 'saved'
        return
      .error (data, status, headers, config) ->
        console.log "Could not get #{file_uri}"
        return

  $scope.refresh = ->
    if $scope.displayed_file?
      open_file $scope.displayed_file.links.self.href
    return

  $scope.undo = ->
    editor.undo()
    return

  $scope.redo = ->
    editor.redo()
    return

  return
require 'codemirror/mode/clike/clike'
code_mirror = require 'codemirror/lib/codemirror'

exports.name = 'kiss_view_controller'

exports.inject = (app) ->
  app.controller exports.name, ['$scope', '$location', '$http', 'app_catalog_provider', exports.controller]
  exports.controller

exports.controller = ($scope, $location, $http, app_catalog_provider) ->
  open_file = (file_uri) ->
    close_file()

    $http.get(file_uri)
    .success (data, status, headers, config) ->
      $scope.displayed_file = data
      editor.setValue(new Buffer($scope.displayed_file.content, 'base64').toString('ascii'));

      setTimeout -> 
        editor.refresh()
      return
    .error (data, status, headers, config) ->
      console.log "Could not get #{file_uri}"
      return

  close_file = ->
    $scope.displayed_file = null
    editor.setValue ''
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
      close_file()
      $scope.selected_project = null
      $scope.selected_file = null

    else
      $scope.selected_project = project
      $scope.selected_file = null

      # load project files
      $http.get(project.links.self.href)
      .success (data, status, headers, config) ->
        console.log data
        $scope.project_resource = data
        return
      .error (data, status, headers, config) ->
        console.log "Could not get #{project.links.self.href}"
        return
    return

  $scope.select_file = (file) ->
    # toggle selection
    if $scope.selected_file is file
      $scope.selected_file = null
      close_file()

    else
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
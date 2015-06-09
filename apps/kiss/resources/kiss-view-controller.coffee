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

  $scope.toggle_include_files_expanded = ->
    $scope.include_files_expanded = not $scope.include_files_expanded
    if not $scope.include_files_expanded and $scope.selected_file_categorie is 'include'
      $scope.selected_file = null
      $scope.selected_file_categorie = null
      close_file()
    return

  $scope.toggle_src_files_expanded = ->
    $scope.src_files_expanded = not $scope.src_files_expanded
    if not $scope.src_files_expanded and $scope.selected_file_categorie is 'src'
      $scope.selected_file = null
      $scope.selected_file_categorie = null
      close_file()
    return

  $scope.toggle_data_files_expanded = ->
    $scope.data_files_expanded = not $scope.data_files_expanded
    if not $scope.data_files_expanded and $scope.selected_file_categorie is 'data'
      $scope.selected_file = null
      $scope.selected_file_categorie = null
      close_file()
    return

  $scope.select_project = (project) ->
    # toggle selection
    if $scope.selected_project is project
      close_file()
      $scope.selected_project = null
      $scope.selected_file = null

      $scope.include_files_expanded = true
      $scope.src_files_expanded = true
      $scope.data_files_expanded = true

    else
      close_file()
      $scope.selected_project = project
      $scope.selected_file = null

      $scope.include_files_expanded = true
      $scope.src_files_expanded = true
      $scope.data_files_expanded = true

      # load project files
      $http.get(project.links.self.href)
      .success (data, status, headers, config) ->
        $scope.project_resource = data
        return
      .error (data, status, headers, config) ->
        console.log "Could not get #{project.links.self.href}"
        return
    return

  $scope.selected_file_categorie = null
  $scope.select_file = (file, categorie) ->
    # toggle selection
    if $scope.selected_file is file
      $scope.selected_file = null
      $scope.selected_file_categorie = null
      close_file()

    else
      $scope.selected_file = file
      $scope.selected_file_categorie = categorie
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

  $scope.show_add_include_file_modal = ->
    $('#new-include-file').modal('show')
    return

  $scope.add_include_file = () ->
    $('#new-include-file').modal('hide')
    if $scope.ws? and $scope.project_resource?
      $http.post($scope.ws.links.include_directory.href,  {name: $scope.project_resource.name, type: 'directory'})
      .finally ->
        $http.post($scope.project_resource.links.include_directory.href,  {name: $("#includeFileName").val(), type: 'file'})
        .success (data, status, headers, config) ->
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
          return
        .error (data, status, headers, config) ->
          console.log "Could not get #{$scope.project_resource.links.include_directory.href}"
          return
        return
    return

  $scope.show_add_source_file_modal = ->
    $('#new-source-file').modal('show')
    return

  $scope.add_source_file = () ->
    $('#new-source-file').modal('hide')
    if $scope.ws? and $scope.project_resource?
      $http.post($scope.ws.links.src_directory.href,  {name: $scope.project_resource.name, type: 'directory'})
      .finally ->
        $http.post($scope.project_resource.links.src_directory.href,  {name: $("#sourceFileName").val(), type: 'file'})
        .success (data, status, headers, config) ->
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
          return
        .error (data, status, headers, config) ->
          console.log "Could not get #{$scope.project_resource.links.src_directory.href}"
          return
        return
    return

  $scope.show_add_data_file_modal = ->
    $('#new-data-file').modal('show')
    return

  $scope.add_data_file = () ->
    $('#new-data-file').modal('hide')
    if $scope.ws? and $scope.project_resource?
      $http.post($scope.ws.links.data_directory.href,  {name: $scope.project_resource.name, type: 'directory'})
      .finally ->
        $http.post($scope.project_resource.links.data_directory.href,  {name: $("#dataFileName").val(), type: 'file'})
        .success (data, status, headers, config) ->
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
          return
        .error (data, status, headers, config) ->
          console.log "Could not get #{$scope.project_resource.links.data_directory.href}"
          return
        return
    return

  $scope.show_add_project_modal = ->
    $('#new-project').modal('show')
    return

  $scope.add_project = () ->
    $('#new-project').modal('hide')
    app_catalog_provider.catalog.then (app_catalog) ->
      projects_resource = app_catalog['Programs']?.web_api?.projects
      if projects_resource?
        $http.post(projects_resource.uri,  {name: $("#projectName").val(), language: 'C' })
        .success (data, status, headers, config) ->
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
          return
        .error (data, status, headers, config) ->
          console.log "Could not get #{projects_resource.uri}"
          return
      return

    return

  $scope.compile = ->
    if $scope.selected_project?
      $http.post('/api/compile', {name: $scope.selected_project.name})
      .success (data, status, headers, config) ->
        $scope.compiler_output = data.result.stderr
        return
      .error (data, status, headers, config) ->
        console.log "Could not post to /api/compile"
        return
    return

  return

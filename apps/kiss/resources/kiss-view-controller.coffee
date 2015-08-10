require 'codemirror/mode/clike/clike'
code_mirror = require 'codemirror/lib/codemirror'

exports.name = 'KissViewController'

exports.inject = (app) ->
  app.controller exports.name, [
    '$scope'
    '$rootScope'
    '$location'
    '$http'
    '$modal'
    'AppCatalogProvider'
    exports.controller
  ]
  return

exports.controller = ($scope, $rootScope, $location, $http, $modal, AppCatalogProvider) ->

  open_file = (file_uri) ->
    close_file()

    $http.get(file_uri)

    .success (data, status, headers, config) ->
      $scope.displayed_file = data
      editor.setValue(new Buffer($scope.displayed_file.content, 'base64').toString('ascii'));
      $scope.documentChanged = false

      setTimeout -> 
        editor.refresh()
      return

    return

  close_file = ->
    $scope.compiler_output = ''
    $scope.displayed_file = null
    editor.setValue ''
    $scope.documentChanged = false
    return

  $scope.delete_file = (file) ->
    close_file()
    modalInstance = $modal.open(
      templateUrl: 'buttons-only-modal.html'
      controller: 'ButtonsOnlyModalController'
      resolve:
        title: -> 'Delete File'
        content: -> 'Are you sure you want to permanently delete this file?'
        button_captions: -> [ 'Yes', 'No' ]
    )
    modalInstance.result.then (button) ->
      if button is 'Yes'
        $http.delete(file.links.self.href)
        reload_project $scope.selected_project
      return

  editor = code_mirror.fromTextArea(document.getElementById('editor'),
    mode: 'text/x-csrc'
    lineNumbers: true
    theme: 'eclipse'
    viewportMargin: Infinity
  )

  editor.on 'change', (e, obj) ->
    $scope.$apply ->
      $scope.documentChanged = true
      return
    return

  saving = false
  editor.on 'beforeChange', (e, obj) ->
    if saving
      obj.cancel()
    return

  # do we have to open a file?
  if $location.search().path?
    file_uri = $location.search().path
    open_file file_uri

  $scope.reload_ws = ->
    close_file()

    AppCatalogProvider.catalog.then (app_catalog) ->
      projects_resource = app_catalog['Programs']?.web_api?.projects
      if projects_resource?
        $http.get(projects_resource.uri)

        .success (data, status, headers, config) ->
          $scope.ws = data
          return

      return

    return

  $scope.reload_ws()

  $scope.show_open = ->
    close_file()
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

  $scope.delete_project = (project) ->
    close_file()
    modalInstance = $modal.open(
      templateUrl: 'buttons-only-modal.html'
      controller: 'ButtonsOnlyModalController'
      resolve:
        title: -> 'Delete Project'
        content: -> 'Are you sure you want to permanently delete this project?'
        button_captions: -> [ 'Yes', 'No' ]
    )
    modalInstance.result.then (button) ->
      if button is 'Yes'
        $http.delete(project.links.self.href)
        .success (data, status, headers, config) ->
          $scope.reload_ws()
          return

      return

  reload_project = (project) ->
    $http.get(project.links.self.href)
    .success (data, status, headers, config) ->
      $scope.project_resource = data
      return

    return
    

  $scope.select_project = (project) ->
    # toggle selection
    if $scope.selected_project is project
      close_file()
      $scope.selected_project = null
      $scope.selected_file = null

      $scope.include_files_expanded = false
      $scope.src_files_expanded = true
      $scope.data_files_expanded = false

    else
      close_file()
      $scope.selected_project = project
      $scope.selected_file = null

      $scope.include_files_expanded = false
      $scope.src_files_expanded = true
      $scope.data_files_expanded = false

      # load project files
      reload_project $scope.selected_project

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

  save_file = ->
    if $scope.displayed_file?
      content = editor.getValue()
      content = new Buffer(content).toString('base64')

      return $http.put($scope.displayed_file.links.self.href, { content: content, encoding: 'ascii' })

  $scope.save = ->
    if $scope.displayed_file?
      saving = true
      save_file()

      .success (data, status, headers, config) ->
        saving = false
        $scope.documentChanged = false
        return

      .error (data, status, headers, config) ->
        saving = false
        return

    return

  on_window_beforeunload = ->
    if $scope.documentChanged
      return 'You have unsaved changes. Are you sure you want to leave this page and discard your changes?'
    else
      return

  window.addEventListener 'beforeunload', on_window_beforeunload

  onRouteChangeOff = $rootScope.$on '$locationChangeStart', (event, newUrl) ->
    if $scope.documentChanged
      modalInstance = $modal.open(
        templateUrl: 'buttons-only-modal.html'
        controller: 'ButtonsOnlyModalController'
        resolve:
          title: -> 'You have unsaved changes'
          content: -> 'You have unsaved changes! Would you like to save them before leaving this page?'
          button_captions: -> [ 'Save', 'Discard', 'Cancel' ]
      )
      modalInstance.result.then (button) ->
        if button is 'Save'
          $scope.save()
          $location.path newUrl.substring($location.absUrl().length - ($location.url().length))
          onRouteChangeOff()
          window.removeEventListener 'beforeunload', on_window_beforeunload
        else if button is 'Discard'
          $location.path newUrl.substring($location.absUrl().length - ($location.url().length))
          onRouteChangeOff()
          window.removeEventListener 'beforeunload', on_window_beforeunload
        return

      event.preventDefault()
    else
      onRouteChangeOff()
      window.removeEventListener 'beforeunload', on_window_beforeunload
    return

  $scope.refresh = ->
    if $scope.displayed_file?
      open_file $scope.displayed_file.links.self.href
    else
      $scope.reload_ws()
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
          reload_project $scope.selected_project
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
          reload_project $scope.selected_project
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
          reload_project $scope.selected_project
          return

        return

    return

  $scope.show_add_project_modal = ->
    $('#new-project').modal('show')
    return

  $scope.add_project = () ->

    $('#new-project').modal('hide')

    AppCatalogProvider.catalog.then (app_catalog) ->
      projects_resource = app_catalog['Programs']?.web_api?.projects
      if projects_resource?
        $http.post(projects_resource.uri,  {name: $("#projectName").val(), language: 'C' })

        .success (data, status, headers, config) ->
          $scope.reload_ws()
          return

      return

    return

  $scope.indent = ->
    editor.execCommand 'selectAll'
    editor.execCommand 'indentAuto'
    editor.setCursor editor.lineCount(), 0
    return

  $scope.compile = ->
    if $scope.selected_project?
      if $scope.displayed_file? 
        save_file()

        .success (data, status, headers, config) ->
          $scope.documentChanged = false
          $http.post('/api/compile', {name: $scope.selected_project.name})

          .success (data, status, headers, config) ->
            $scope.compiler_output = 'Compilation finished:\n' + data.result.stderr + data.result.stdout
            return

          return

      else
        $http.post('/api/compile', {name: $scope.selected_project.name})

        .success (data, status, headers, config) ->
          $scope.compiler_output = data.result.stderr
          return

      return

  return

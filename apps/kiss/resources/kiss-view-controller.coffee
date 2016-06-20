require 'codemirror/mode/clike/clike'
code_mirror = require 'codemirror/lib/codemirror'

exports.name = 'KissViewController'

exports.inject = (app) ->
  app.controller exports.name, [
    '$scope'
    '$rootScope'
    '$location'
    '$http'
    '$timeout'
    'AppCatalogProvider'
    'ButtonsOnlyModalFactory'
    'DownloadProjectModalFactory'
    'FilenameModalFactory'
    exports.controller
  ]
  return

exports.controller = (
  $scope
  $rootScope
  $location
  $http
  $timeout
  AppCatalogProvider
  ButtonsOnlyModalFactory
  DownloadProjectModalFactory
  FilenameModalFactory) ->
  $scope.is_compiling = false

  $scope.documentChanged = false

  $scope.$on '$routeUpdate', (next, current) ->
    if ($scope.displayed_file?.name isnt $location.search().file) or ($scope.selected_project?.name isnt $location.search().project)
      $scope.reload_ws()

  editor = code_mirror.fromTextArea(document.getElementById('editor'),
    mode: 'text/x-csrc'
    lineNumbers: true
    theme: 'eclipse'
    viewportMargin: Infinity
  )

  editor.on 'change', (e, obj) ->
    $timeout ->
      $scope.documentChanged = true
      return
    return

  saving = false
  editor.on 'beforeChange', (e, obj) ->
    if saving
      obj.cancel()
    return

  $scope.reload_ws = ->
    AppCatalogProvider.catalog.then (app_catalog) ->
      projects_resource = app_catalog['Programs']?.web_api?.projects
      if projects_resource?
        $http.get(projects_resource.uri)

        .success (data, status, headers, config) ->
          $scope.ws = data

          if $location.search().project?
            selected = (project for project in $scope.ws.projects when project.name is $location.search().project)
            if selected[0]
              $scope.select_project selected[0]
            else
              $location.search 'project', null

          return

      return

    return

  $scope.reload_ws()

  $scope.delete_project = (project) ->
    ButtonsOnlyModalFactory.open(
      'Delete Project'
      'Are you sure you want to permanently delete this project?'
      [ 'Yes', 'No' ])
    .then (button) ->
      if button is 'Yes'
        $scope.close_project()
        $http.delete(project.links.self.href)
        .success (data, status, headers, config) ->
          $scope.reload_ws()

  $scope.close_project = ->
    $scope.close_file()

    $scope.project_resource = null

    $location.search 'project', null
    $scope.selected_project = null

  $scope.select_project = (project) ->
    $scope.selected_project = project
    $location.search 'project', project.name if $location.search().project isnt project.name

    $http.get(project.links.self.href)
    .success (data, status, headers, config) ->
      $scope.project_resource = data

      selected_file = null
      selected_file_cat = null

      if $location.search().file?
        selected = []
        if $location.search().cat is 'include' and $scope.project_resource.include_files?
          selected = (file for file in $scope.project_resource.include_files when file.name is $location.search().file)
        else if $location.search().cat is 'src' and $scope.project_resource.source_files?
          selected = (file for file in $scope.project_resource.source_files when file.name is $location.search().file)
        else if $location.search().cat is 'data' and $scope.project_resource.data_files?
          selected = (file for file in $scope.project_resource.data_files when file.name is $location.search().file)
        selected_file = selected[0]
        selected_file_cat = $location.search().cat

      if not selected_file and $scope.project_resource.source_files
        selected_file = $scope.project_resource.source_files[0]
        selected_file_cat = 'src'

      if selected_file
        $scope.select_file selected_file, selected_file_cat
      else
        $scope.close_file()

  $scope.select_file = (file, file_type) ->
    $scope.selected_file = file
    $scope.compiler_output = ''
    $location.search 'file', file.name
    $location.search 'cat', file_type

    $http.get($scope.selected_file.links.self.href)
    .success (data, status, headers, config) ->
      $scope.display_file_menu = false
      $scope.displayed_file = data

      $timeout ->
        editor.setValue(new Buffer(data.content, 'base64').toString('ascii'))
        editor.refresh()
        $timeout ->
          $scope.documentChanged = false
      return

    return

  $scope.close_file = ->
    $scope.compiler_output = ''
    $scope.display_file_menu = false
    $scope.displayed_file = null
    $scope.selected_file = null
    editor.setValue ''
    $scope.documentChanged = false
    $location.search 'file', null
    $location.search 'cat', null

  $scope.delete_file = (file) ->
    ButtonsOnlyModalFactory.open(
      'Delete File'
      'Are you sure you want to permanently delete this file?'
      [ 'Yes', 'No' ])
    .then (button) ->
      if button is 'Yes'
        $http.delete(file.links.self.href)
        $scope.close_file()
        $scope.select_project $scope.selected_project
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

    # workaround to detect in-app url updates
    if newUrl.indexOf('/#/apps/kiss') isnt -1
      return

    # remove query string
    if newUrl.indexOf('?') isnt -1
      newUrl = newUrl.substring 0, newUrl.indexOf('?')

    # remove host:port
    newUrl = newUrl.substring($location.absUrl().length - ($location.url().length))

    if $scope.documentChanged
      ButtonsOnlyModalFactory.open(
        'You have unsaved changes'
        'You have unsaved changes! Would you like to save them before leaving this page?'
        [ 'Save', 'Discard', 'Cancel' ])
      .then (button) ->
        if button is 'Save'
          $scope.save()
          $location.path newUrl.substring($location.absUrl().length - ($location.url().length))
          onRouteChangeOff()
          window.removeEventListener 'beforeunload', on_window_beforeunload
        else if button is 'Discard'
          $location.path newUrl
          onRouteChangeOff()
          window.removeEventListener 'beforeunload', on_window_beforeunload
        return

      event.preventDefault()
    else
      onRouteChangeOff()
      window.removeEventListener 'beforeunload', on_window_beforeunload
    return

  $scope.refresh = ->

  $scope.undo = ->
    editor.undo()
    return

  $scope.redo = ->
    editor.redo()
    return

  $scope.download_project = (project) ->
    DownloadProjectModalFactory.open project

  $scope.show_add_include_file_modal = ->
    FilenameModalFactory.open(
      'Create New Include File'
      'Choose a filename:'
      'Filename'
      [ '.h' ]
      'Create')
      .then (data) ->
        if $scope.ws? and $scope.project_resource?
          $http.post($scope.ws.links.include_directory.href,  {name: $scope.project_resource.name, type: 'directory'})

          .finally ->
            $http.post($scope.project_resource.links.include_directory.href,  {name: data.filename + data.extension, type: 'file'})

            .success (data, status, headers, config) ->
              $scope.select_project $scope.selected_project

  $scope.show_add_source_file_modal = ->
    FilenameModalFactory.open(
      'Create New Source File'
      'Choose a filename:'
      'Filename'
      [ '.c', '.py' ]
      'Create')
      .then (data) ->
        if $scope.ws? and $scope.project_resource?
          $http.post($scope.ws.links.src_directory.href,  {name: $scope.project_resource.name, type: 'directory'})

          .finally ->
            $http.post($scope.project_resource.links.src_directory.href,  {name: data.filename + data.extension, type: 'file'})

            .success (data, status, headers, config) ->
              $scope.select_project $scope.selected_project

  $scope.show_add_data_file_modal = ->
    FilenameModalFactory.open(
      'Create User Data File'
      'Choose a filename:'
      'Filename'
      null
      'Create')
      .then (data) ->
        if $scope.ws? and $scope.project_resource?
          $http.post($scope.ws.links.data_directory.href,  {name: $scope.project_resource.name, type: 'directory'})

          .finally ->
            $http.post($scope.project_resource.links.data_directory.href,  {name: data.filename, type: 'file'})

            .success (data, status, headers, config) ->
              $scope.select_project $scope.selected_project

  $scope.close_file_menu = ->
    $scope.display_file_menu = false

  $scope.open_file_menu = ->
    $scope.display_file_menu = true

  $scope.show_add_project_modal = ->
    $('#new-project').modal('show')
    return

  $scope.hide_add_project_modal = ->
    $('#new-project').modal('hide')
    

  $scope.add_project = () ->

    $('#new-project').modal('hide')

    AppCatalogProvider.catalog.then (app_catalog) ->
      projects_resource = app_catalog['Programs']?.web_api?.projects
      if projects_resource?
        $http.post(projects_resource.uri,  {name: $("#projectName").val(), language: $("#programmingLanguage").val(), src_file_name: $("#sourceFileName").val()})

        .success (data, status, headers, config) ->
          $scope.reload_ws()
          return

      return

    return

  $scope.defaultProgrammingLanguage = 'C';

  $scope.change_filename = () ->

    if ($("#programmingLanguage").val() == "Python")
      $("#sourceFileName").val("main.py")
    else
      $("#sourceFileName").val("main.c")

    return

  $scope.indent = ->
    editor.execCommand 'selectAll'
    editor.execCommand 'indentAuto'
    editor.setCursor editor.lineCount(), 0
    return

  compile = (project_name) ->
    $scope.is_compiling = true
    $http.post('/api/compile', {name: project_name})

    .success (data, status, headers, config) ->
      $scope.is_compiling = false
      if data.result.error?
        $scope.compilation_state = 'Compilation Failed'
        if data.result.error?.message?
          $scope.compiler_output = 'Compilation Failed\n\n' + data.result.error.message
        else
          $scope.compiler_output = 'Compilation Failed\n\n' + data.result.stderr + data.result.stdout
      else if data.result.stderr
        $scope.compilation_state = 'Compilation Succeeded with Warnings'
        $scope.compiler_output = 'Compilation Succeeded with Warnings\n\n' + data.result.stderr + data.result.stdout
      else
        $scope.compilation_state = 'Compilation succeeded'
        $scope.compiler_output = 'Compilation succeeded\n\n' + data.result.stdout

  $scope.compile = ->
    $scope.compiler_output = null
    if $scope.selected_project?
      if $scope.displayed_file? 
        save_file()

        .success (data, status, headers, config) ->
          $scope.documentChanged = false
          compile $scope.selected_project.name

      else
        compile $scope.selected_project.name

exports.name = 'FsViewController'

exports.inject = (app) ->
  app.controller exports.name, [
    '$scope'
    '$http'
    'AppCatalogProvider'
    'UserManagerService'
    exports.controller
  ]
  return

exports.controller = ($scope, $http, AppCatalogProvider, UserManagerService) ->

  open_dir = (uri) ->
    $scope.current = undefined
    $scope.selected = undefined
    $http.get uri

    .success (data, status, headers, config) ->
      $scope.current = data
      return

    return
  
  root_dir_uri = undefined
  
  AppCatalogProvider.catalog.then (app_catalog) ->
    fs_api = app_catalog['Host Filesystem']?.web_api?.fs
    if fs_api?
      open_dir fs_api.uri
      root_dir_uri = fs_api.uri
    return

  UserManagerService.get_current_user().then (current_user) ->
    $scope.home_uri = current_user?.preferences?.workspace?.links?.self?.href
    return

  $scope.open_directory = (directory) ->
    open_dir directory.links.self.href
    return

  $scope.can_up = () ->
    return $scope.current and $scope.current.links.self.href isnt root_dir_uri

  $scope.select_child = (child) ->
    if $scope.selected is child and child.type is 'Directory'
      $scope.open_directory child
    else
      $scope.selected = child
    return

  $scope.home = () ->
    open_dir $scope.home_uri if $scope.home_uri?
    return

  $scope.root = () ->
    open_dir root_dir_uri if root_dir_uri?
    return

  $scope.up = () ->
    if $scope.current.parent?
      open_dir $scope.current.parent.links.self.href
    return

  $scope.reload = () ->
    open_dir $scope.current.links.self.href
    return

  return
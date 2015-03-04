exports.name = 'fs_view_controller'

exports.inject = (app) ->
  app.controller exports.name, ['$scope', '$http', 'app_catalog_provider', exports.controller]
  exports.controller

exports.controller = ($scope, $http, app_catalog_provider) ->
  open_dir = (uri) ->
    $scope.current = undefined
    $http.get(uri)
    .success (data, status, headers, config) ->
      $scope.current = data
      return
    .error (data, status, headers, config) ->
      console.log "Could not get #{web_api.rel_uri}"
      return
    return
  
  root_dir_uri = undefined
  
  app_catalog_provider.catalog.then (app_catalog) ->
    for web_api in app_catalog['Host Filesystem']['web_api']
      if web_api.id is 'fs'
        open_dir(web_api.uri)
        root_dir_uri = web_api.uri
        return
    return

  $scope.open_child_directory = (child) ->
    open_dir(child.href)
    return

  $scope.root = () ->
    open_dir(root_dir_uri) if root_dir_uri?
    return

  $scope.up = () ->
    if $scope.current.links.parent?
      open_dir($scope.current.links.parent.href)
    return

  $scope.reload = () ->
    open_dir($scope.current.links.self.href)
    return
  return
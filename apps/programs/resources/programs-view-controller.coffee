exports.name = 'programs_view_controller'

exports.inject = (app) ->
  app.controller exports.name, ['$scope', '$http', 'app_catalog_provider', exports.controller]
  exports.controller

exports.controller = ($scope, $http, app_catalog_provider) ->
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
    $scope.selected = project
    return

  return
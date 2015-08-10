exports.name = 'ProgramsViewController'

exports.inject = (app) ->
  app.controller exports.name, [
    '$scope'
    '$http'
    'AppCatalogProvider'
    exports.controller
  ]
  return

exports.controller = ($scope, $http, AppCatalogProvider) ->

  AppCatalogProvider.catalog.then (app_catalog) ->
    fs_api = app_catalog['Programs']?.web_api?.projects
    if fs_api?
      $http.get(fs_api.uri)

      .success (data, status, headers, config) ->
        $scope.ws = data
        return

    return

  $scope.select_project = (project) ->
    $scope.selected = project
    return

  return
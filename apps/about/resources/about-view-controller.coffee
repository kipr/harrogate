exports.name = 'AboutViewController'

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
    about_api = app_catalog['About']?.web_api?.about
    if about_api?
      $http.get(about_api.uri)

      .success (data, status, headers, config) ->
        $scope.about = data

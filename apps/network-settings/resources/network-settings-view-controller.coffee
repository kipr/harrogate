exports.name = 'NetworkSettingsViewController'

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
    settings_api = app_catalog['Network-Settings']?.web_api?.settings
    #if settings_api?
    #  $http.get(settings_api.uri)

    #  .success (data, status, headers, config) ->
    #    $scope.settings = data
exports.name = 'settings_view_controller'

exports.inject = (app) ->
  app.controller exports.name, [
    '$scope'
    '$http'
    'app_catalog_provider'
    exports.controller
  ]
  exports.controller

exports.controller = ($scope, $http, app_catalog_provider) ->
  app_catalog_provider.catalog.then (app_catalog) ->
    settings_api = app_catalog['Settings']?.web_api?.settings
    if settings_api?
      $http.get(settings_api.uri)
      .success (data, status, headers, config) ->
        $scope.settings = data
        console.log $scope.settings
        return
      .error (data, status, headers, config) ->
        console.log "Could not get #{uri}"
        return
    return

  return
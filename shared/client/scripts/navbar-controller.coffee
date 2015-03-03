exports.inject = (app) ->
  app.controller 'navbar_controller',
    [
      '$scope'
      '$location'
      'app_catalog_provider'
      exports.controller
    ]
  exports.controller

exports.controller = ($scope, $location, app_catalog_provider) ->
  $scope.$location = $location
    
  app_catalog_provider.apps_by_category.then (apps_by_category) ->
    apps = []

    # home app first
    apps.push [app_catalog_provider.home_app] if app_catalog_provider.home_app?

    # then the other by category
    for cat, app_list of apps_by_category
      list = app_list.filter (app) -> not app.hidden and app.navbar
      list.sort (a, b) -> a.priority - b.priority
      apps.push list

    $scope.app_catalog = [].concat.apply([], apps)

  return
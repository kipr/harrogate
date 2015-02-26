angular.module 'harrogateNavbar', ['harrogateApps']
.controller('HarrogateNavbarCtrl', ['$scope', '$location', 'harrogateAppsCatalog'
  ($scope, $location, harrogateAppsCatalog) ->
    $scope.$location = $location
    
    harrogateAppsCatalog.apps_by_category.then (apps_by_category) ->
      apps = []

      # home app first
      apps.push [harrogateAppsCatalog.home_app] if harrogateAppsCatalog.home_app?

      # then the other by category
      for cat, app_list of apps_by_category
        list = app_list.filter (app) -> not app.hidden and app.navbar
        list.sort (a, b) -> a.priority - b.priority
        apps.push list

      $scope.app_catalog = [].concat.apply([], apps)

    return
])
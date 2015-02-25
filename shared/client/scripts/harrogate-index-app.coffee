angular.module 'harrogateIndexApp', [
  'ngRoute',
  'harrogateNavbar']
.config([
  '$routeProvider'
  ($routeProvider) ->
    
    # redirect by default to home (let's hope that an app called 'home' always exists...)
    $routeProvider.when('/', redirectTo: '/apps/home')
    $routeProvider.when("/apps/home",
      templateUrl: '/apps/home')
    
    # add the routes for the apps
    for app_name, app_obj of app_catalog
      $routeProvider.when(app_obj.angularjs_route,
        templateUrl: app_obj.nodejs_route)
    
    return
])
angular = require 'angular'
require 'angular-route'

app = angular.module 'harrogateIndexApp', ['ngRoute']

require('./app-catalog-provider.coffee').inject app
require('./navbar-controller.coffee').inject app

app.config([
  '$routeProvider'
  ($routeProvider) ->
    
    # redirect by default to home (let's hope that an app called 'home' always exists...)
    $routeProvider.when('/', redirectTo: '/apps/home')

    # add the routes for the apps
    for app_name, app_obj of app_catalog
      if app_obj.angular_ctrl?
        require(app_name).inject app
    
        $routeProvider.when(app_obj.angularjs_route,
          templateUrl: app_obj.nodejs_route
          controller: require(app_name).controller
        )
      else
        $routeProvider.when(app_obj.angularjs_route,
          templateUrl: app_obj.nodejs_route
        )
    
    return
])

app.run()
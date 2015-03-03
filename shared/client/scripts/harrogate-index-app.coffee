﻿angular = require 'angular'
require 'angular-route'

app = angular.module 'harrogateIndexApp', ['ngRoute']

require('./harrogate-apps-module.coffee').inject app
require('./harrogate-navbar-module.coffee').inject app

app.config([
  '$routeProvider'
  ($routeProvider) ->
    
    # redirect by default to home (let's hope that an app called 'home' always exists...)
    $routeProvider.when('/', redirectTo: '/apps/home')

    # add the routes for the apps
    for app_name, app_obj of app_catalog
      $routeProvider.when(app_obj.angularjs_route,
        templateUrl: app_obj.nodejs_route)
    
    return
])

app.run()
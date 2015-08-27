angular = require 'angular'
require 'angular-route'

app = angular.module 'harrogateIndexApp', ['ngRoute', 'ui.bootstrap']

require('./app-catalog-provider.coffee').inject app
require('./buttons-only-modal-factory-service.coffee').inject app
require('./download-project-modal-factory-service.coffee').inject app
require('./filename-modal-factory-service.coffee').inject app
require('./terminal-directive.coffee').inject app
require('./user-manager-service.coffee').inject app

# inject the apps
for app_name, app_obj of app_catalog
  if app_obj.angular_ctrl?
    require(app_name).inject app

# from http://stackoverflow.com/questions/14512583/how-to-generate-url-encoded-anchor-links-with-angularjs
app.filter 'escape', ->
  window.encodeURIComponent

app.filter 'capitalize', ->
  return (input) ->
    return if input? then input.charAt(0).toUpperCase() + input.substr(1) else ''

app.service 'authRequiredInterceptor', ['$q', '$location', ($q, $location) ->
  class AuthRequiredInterceptor
    constructor: ->
      @last_intercepted_path = null

    responseError: (response) =>
      if response.status is 401
        @last_intercepted_path = $location.path()
        $location.path '/apps/user'
      return $q.reject response

  return new AuthRequiredInterceptor
]

app.controller('statusBarCtrl'
  ['$scope', 'UserManagerService'
  ($scope, UserManagerService) ->
    UserManagerService.get_current_user().then (current_user) ->
      $scope.current_user = current_user
      return
  
])

app.config([
  '$routeProvider', '$httpProvider', 
  ($routeProvider, $httpProvider, $location) ->
    
    # redirect by default to home (let's hope that an app called 'home' always exists...)
    $routeProvider.when('/', redirectTo: '/apps/home')

    # add the routes for the apps
    for app_name, app_obj of app_catalog
      if app_obj.angular_ctrl?
        $routeProvider.when(app_obj.angularjs_route,
          templateUrl: app_obj.nodejs_route
          controller: require(app_name).controller
          reloadOnSearch: false
        )
      else
        $routeProvider.when(app_obj.angularjs_route,
          templateUrl: app_obj.nodejs_route
        )

    # setup 401 interception
    $httpProvider.interceptors.push 'authRequiredInterceptor'
    return
])

app.directive 'setFocus', ($timeout, $parse) ->
  return {
    restrict: "A"
    scope: { setFocus: '=' }

    link: ($scope, element, attrs) ->

      $scope.$watch 'setFocus', (value) ->
        if value is true

          $timeout ->
            element[0].focus()
            return

        return

      return
    }

app.run()
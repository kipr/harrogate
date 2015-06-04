exports.name = 'users_view_controller'

exports.inject = (app) ->
  app.controller exports.name,
    [
      '$scope'
      '$http'
      '$location'
      'authRequiredInterceptor'
      exports.controller
    ]
  exports.controller

exports.controller = ($scope, $http, $location, authRequiredInterceptor) ->

  $scope.login = ->
    $http.post('/login', { username: $scope.username, password: $scope.password })
    .success (data, status, headers, config) ->
      if authRequiredInterceptor.last_intercepted_path?
        $location.path authRequiredInterceptor.last_intercepted_path
      else
        $location.path '/'
      return
  return
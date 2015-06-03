exports.name = 'users_view_controller'

exports.inject = (app) ->
  app.controller exports.name,
    [
      '$scope'
      '$http'
      exports.controller
    ]
  exports.controller

exports.controller = ($scope, $http) ->

  $scope.login = ->
    $http.post('/login', { username: $scope.username, password: $scope.password })
    .success (data, status, headers, config) ->
      alert 'saved'
      return
  return
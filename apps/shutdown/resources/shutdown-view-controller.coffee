exports.name = 'ShutdownViewController'

exports.inject = (app) ->
  app.controller exports.name, [
    '$scope'
    '$http'
    '$location'
    'ButtonsOnlyModalFactory'
    exports.controller
  ]
  return

exports.controller = ($scope, $http, $location, ButtonsOnlyModalFactory) ->

  $scope.shutting_down = false

  ButtonsOnlyModalFactory.open(
    'Shut down the System'
    'Are you sure you want to shut down the system?'
    [ 'Yes', 'No' ])
  .then (button) ->
    if button is 'Yes'
      $scope.shutting_down = true
      $http.post('/api/shutdown')
    else if button is 'No'
      $location.path('/apps/home')

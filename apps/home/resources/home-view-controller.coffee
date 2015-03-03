exports.name = 'home_view_controller'

exports.inject = (app) ->
  app.controller exports.name,
    [
      '$scope'
      exports.controller
    ]
  exports.controller

exports.controller = ($scope) ->
  $scope.show_welcome = true
  $scope.click_learn_more = ->
    alert 'Implement me!!!'
  return 
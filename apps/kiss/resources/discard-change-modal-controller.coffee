exports.name = 'DiscardChangeModalController'

exports.inject = (app) ->
  app.controller exports.name, [
    '$scope'
    '$modalInstance'
    exports.controller
  ]
  return

exports.controller = ($scope, $modalInstance) ->

  $scope.save = ->
    $modalInstance.close 'Save'
    return

  $scope.discard = ->
    $modalInstance.dismiss 'Discard'
    return

  $scope.cancel = ->
    $modalInstance.dismiss 'Cancel'
    return

  return
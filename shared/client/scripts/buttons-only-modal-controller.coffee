exports.name = 'ButtonsOnlyModalController'

exports.inject = (app) ->
  app.controller exports.name, [
    '$scope'
    '$modalInstance'
    'title'
    'content'
    'button_captions'
    exports.controller
  ]
  return

exports.controller = ($scope, $modalInstance, title, content, button_captions) ->

  $scope.title = title
  $scope.content = content
  $scope.button_captions = button_captions

  $scope.click = (button) ->
    $modalInstance.close button
    return

  $scope.dismiss = ->
    $modalInstance.dismiss()
    return

  return
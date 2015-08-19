exports.name = 'ButtonsOnlyModalFactory'

exports.service = ($modal) ->
  service =
    open: (title, content, button_captions) ->
      modalInstance = $modal.open(
        templateUrl: 'buttons-only-modal.html'
        controller: 'ButtonsOnlyModalController'
        resolve:
          title: -> title
          content: -> content
          button_captions: -> button_captions
      )
      return modalInstance.result

  return service

controller = ($scope, $modalInstance, title, content, button_captions) ->

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

exports.inject = (app) ->
  app.controller 'ButtonsOnlyModalController', [
    '$scope'
    '$modalInstance'
    'title'
    'content'
    'button_captions'
    controller
  ]

  app.service exports.name, [
    '$modal'
    exports.service
  ]
  return
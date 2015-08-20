exports.name = 'FilenameModalFactory'

exports.service = ($modal) ->
  service =
    open: (title, content, placeholder, extensions, button_caption) ->
      modalInstance = $modal.open(
        templateUrl: 'filename-modal.html'
        controller: 'FilenameModalController'
        resolve:
          title: -> title
          content: -> content
          placeholder: -> placeholder
          extensions: -> extensions
          button_caption: -> button_caption
      )
      return modalInstance.result

  return service

controller = ($scope, $modalInstance, title, content, placeholder, extensions, button_caption) ->

  $scope.data =
    filename: null
    extension: null

  $scope.title = title
  $scope.content = content
  $scope.placeholder = placeholder
  $scope.button_caption = button_caption
  $scope.extensions = extensions

  if $scope.extensions?
    $scope.data.extension = $scope.extensions[0]

  $scope.click = () ->
    if $scope.data.filename? and $scope.data.filename != ''
      $modalInstance.close $scope.data
    return

  $scope.dismiss = ->
    $modalInstance.dismiss()
    return

  return

exports.inject = (app) ->
  app.controller 'FilenameModalController', [
    '$scope'
    '$modalInstance'
    'title'
    'content'
    'placeholder'
    'extensions'
    'button_caption'
    controller
  ]

  app.service exports.name, [
    '$modal'
    exports.service
  ]
  return
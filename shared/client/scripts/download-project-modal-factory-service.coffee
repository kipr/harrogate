exports.name = 'DownloadProjectModalFactory'

exports.service = ($modal) ->
  service =
    open: (project_resource) ->
      modalInstance = $modal.open(
        templateUrl: 'download-project-modal.html'
        controller: 'DownloadProjectModalController'
        resolve:
          project_resource: -> project_resource
      )
      return modalInstance.result

  return service

controller = ($scope, $modalInstance, project_resource) ->

  $scope.project_resource = project_resource

  $scope.dismiss = ->
    $modalInstance.dismiss()

exports.inject = (app) ->
  app.controller 'DownloadProjectModalController', [
    '$scope'
    '$modalInstance'
    'project_resource'
    controller
  ]

  app.service exports.name, [
    '$modal'
    exports.service
  ]
  return
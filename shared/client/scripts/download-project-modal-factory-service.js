var controller;

exports.name = 'DownloadProjectModalFactory';

exports.service = function($modal) {
  var service;
  service = {
    open: function(project_resource) {
      var modalInstance;
      modalInstance = $modal.open({
        templateUrl: 'download-project-modal.html',
        controller: 'DownloadProjectModalController',
        resolve: {
          project_resource: function() {
            return project_resource;
          }
        }
      });
      return modalInstance.result;
    }
  };
  return service;
};

controller = function($scope, $modalInstance, project_resource) {
  $scope.project_resource = project_resource;
  return $scope.dismiss = function() {
    return $modalInstance.dismiss();
  };
};

exports.inject = function(app) {
  app.controller('DownloadProjectModalController', ['$scope', '$modalInstance', 'project_resource', controller]);
  app.service(exports.name, ['$modal', exports.service]);
};

var controller;

exports.name = 'ButtonsOnlyModalFactory';

exports.service = function($modal) {
  var service;
  service = {
    open: function(title, content, button_captions) {
      var modalInstance;
      modalInstance = $modal.open({
        templateUrl: 'buttons-only-modal.html',
        controller: 'ButtonsOnlyModalController',
        resolve: {
          title: function() {
            return title;
          },
          content: function() {
            return content;
          },
          button_captions: function() {
            return button_captions;
          }
        }
      });
      return modalInstance.result;
    }
  };
  return service;
};

controller = function($scope, $modalInstance, title, content, button_captions) {
  $scope.title = title;
  $scope.content = content;
  $scope.button_captions = button_captions;
  $scope.click = function(button) {
    $modalInstance.close(button);
  };
  $scope.dismiss = function() {
    $modalInstance.dismiss();
  };
};

exports.inject = function(app) {
  app.controller('ButtonsOnlyModalController', ['$scope', '$modalInstance', 'title', 'content', 'button_captions', controller]);
  app.service(exports.name, ['$modal', exports.service]);
};

var controller;

exports.name = 'FilenameModalFactory';

exports.service = function($modal) {
  var service;
  service = {
    open: function(title, placeholder, extensions, button_caption) {
      var modalInstance;
      modalInstance = $modal.open({
        templateUrl: 'filename-modal.html',
        controller: 'FilenameModalController',
        resolve: {
          title: function() {
            return title;
          },
          placeholder: function() {
            return placeholder;
          },
          extensions: function() {
            return extensions;
          },
          button_caption: function() {
            return button_caption;
          }
        }
      });
      return modalInstance.result;
    }
  };
  return service;
};

controller = function($scope, $modalInstance, title, placeholder, extensions, button_caption) {
  $scope.data = {
    filename: null,
    extension: null
  };
  $scope.title = title;
  $scope.placeholder = placeholder;
  $scope.button_caption = button_caption;
  $scope.extensions = extensions; 

  if ($scope.extensions != null) {
    $scope.data.extension = $scope.extensions[0];
  }
  $scope.click = function() {
    var new_valid = $scope.data.filename != null && $scope.data.filename !== '';
    var upload_valid = $scope.data.upload != null && $scope.data.upload.name !== '';
    if (new_valid || upload_valid) {
      $modalInstance.close($scope.data);
    }
  };
  $scope.dismiss = function() {
    $modalInstance.dismiss();
  };
};

exports.inject = function(app) {
  app.controller('FilenameModalController', ['$scope', '$modalInstance', 'title', 'placeholder', 'extensions', 'button_caption', controller]);
  app.service(exports.name, ['$modal', exports.service]);
};

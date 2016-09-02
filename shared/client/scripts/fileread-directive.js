var angular = require('angular');

exports.name = 'fileread';

exports.directive = function () {
  return {
    scope: {
      fileread: "="
    },
    link: function (scope, element, attributes) {
      element.bind("change", function (changeEvent) {
      var reader = new FileReader();
      reader.onload = function (loadEvent) {
        scope.$apply(function () {
          scope.fileread = {
            name: changeEvent.target.files[0].name,
            content: loadEvent.target.result
          };
        });
      }
      reader.readAsText(changeEvent.target.files[0]);
      });
    }
  }
};

exports.inject = function(app) {
  app.directive(exports.name, [exports.directive]);
};
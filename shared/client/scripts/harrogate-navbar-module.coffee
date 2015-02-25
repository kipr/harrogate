angular.module 'harrogateNavbar', []
.controller('HarrogateNavbarCtrl', ['$scope', '$location',
  ($scope, $location) ->
    $scope.$location = $location
    $scope.app_catalog = app_catalog
    return
])
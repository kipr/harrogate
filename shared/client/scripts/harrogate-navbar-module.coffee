angular.module 'harrogateNavbar', []
.controller('HarrogateNavbarCtrl', ['$scope', '$location',
  ($scope, $location) ->
    $scope.$location = $location
    return
])
exports.name = 'ServosViewController'

exports.inject = (app) ->
  app.controller exports.name, [
    '$scope'
    '$interval'
    exports.controller
  ]
  return

exports.controller = ($scope, $interval) ->

  $scope.servos = 
    for i in [0...4]
      {
        name: "Servo #{i}"
        position: 0
        started: false
      }

  $scope.selected_servo = $scope.servos[0]

  $scope.select_servo = (servo) ->
    $scope.selected_servo = servo

  $('#servo-0-slider').roundSlider
    sliderType: 'min-range'
    showTooltip: true
    radius: 105
    width: 16
    value: 75
    handleSize: 0
    handleShape: 'square'
    circleShape: 'pie'
    startAngle: 315

  $('#servo-1-slider').roundSlider
    sliderType: 'min-range'
    showTooltip: true
    radius: 105
    width: 16
    value: 75
    handleSize: 0
    handleShape: 'square'
    circleShape: 'pie'
    startAngle: 315

  $('#servo-2-slider').roundSlider
    sliderType: 'min-range'
    showTooltip: true
    radius: 105
    width: 16
    value: 75
    handleSize: 0
    handleShape: 'square'
    circleShape: 'pie'
    startAngle: 315

  $('#servo-3-slider').roundSlider
    sliderType: 'min-range'
    showTooltip: true
    radius: 105
    width: 16
    value: 75
    handleSize: 0
    handleShape: 'square'
    circleShape: 'pie'
    startAngle: 315


  $('#position-slider-compact').roundSlider
    sliderType: 'min-range'
    showTooltip: true
    radius: 75
    width: 16
    value: 75
    handleSize: 0
    handleShape: 'square'
    circleShape: 'pie'
    startAngle: 315

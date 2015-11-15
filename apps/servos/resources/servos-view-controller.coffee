exports.name = 'ServosViewController'

exports.inject = (app) ->
  app.controller exports.name, [
    '$scope'
    '$interval'
    exports.controller
  ]
  return

exports.controller = ($scope, $interval) ->

  pps = 1000

  $scope.servos = 
    for i in [0...4]
      {
        name: "Servos #{i}"
        speed: 0
        power: 0
        position: 0
        selected: false
      }

  $scope.selected_servo = $scope.servos[0]

  $scope.select_servo = (servo) ->
    $scope.selected_servo = servo

  $scope.stop_servo = (servo) ->
    servo.speed = 0
    servo.power = 0

  $('#speed-slider').roundSlider
    sliderType: 'min-range'
    showTooltip: true
    radius: 105
    width: 16
    value: 75
    handleSize: 0
    handleShape: 'square'
    circleShape: 'pie'
    startAngle: 315

  $('#power-slider').roundSlider
    sliderType: 'min-range'
    showTooltip: true
    radius: 105
    width: 16
    value: 75
    handleSize: 0
    handleShape: 'square'
    circleShape: 'pie'
    startAngle: 315

  $interval(( ->
    for servo in $scope.servos
      servo.position += servo.power * 0.01 * pps
      servo.speed = servo.power * 0.01 * pps
    ), 1000)

  
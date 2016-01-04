exports.name = 'MotorsViewController'

exports.inject = (app) ->
  app.controller exports.name, [
    '$scope'
    '$interval'
    exports.controller
  ]
  return

exports.controller = ($scope, $interval) ->

  pps = 1000

  $scope.motors = 
    for i in [0...4]
      {
        name: "Motor #{i}"
        speed: 0
        power: 0
        position: 0
        selected: false
      }

  $scope.selected_motor = $scope.motors[0]

  $scope.select_motor = (motor) ->
    $scope.selected_motor = motor

  $scope.stop_motor = (motor) ->
    motor.speed = 0
    motor.power = 0

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
    for motor in $scope.motors
      motor.position += motor.power * 0.01 * pps
      motor.speed = motor.power * 0.01 * pps

    ), 1000)

  
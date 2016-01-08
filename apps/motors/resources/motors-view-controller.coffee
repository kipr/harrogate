exports.name = 'MotorsViewController'

exports.inject = (app) ->
  app.controller exports.name, [
    '$scope'
    '$http'
    '$interval'
    exports.controller
  ]
  return

exports.controller = ($scope, $http, $interval) ->
  $scope.selected_action = 'speed'

  $scope.select_action = (action) ->
    $scope.selected_action = action

  pps = 1000

  $scope.motors = 
    for i in [0...4]
      {
        name: "Motor #{i}"
        i: i
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

  $('#speed-slider-0').roundSlider
    sliderType: 'min-range'
    showTooltip: true
    radius: 75
    width: 16
    min: -1000
    max: 1000
    step: 20
    value: 0
    handleSize: 0
    handleShape: 'square'
    circleShape: 'pie'
    startAngle: 315

  $('#speed-slider-1').roundSlider
    sliderType: 'min-range'
    showTooltip: true
    radius: 75
    width: 16
    min: -1000
    max: 1000
    step: 20
    value: 0
    handleSize: 0
    handleShape: 'square'
    circleShape: 'pie'
    startAngle: 315

  $('#speed-slider-2').roundSlider
    sliderType: 'min-range'
    showTooltip: true
    radius: 75
    width: 16
    min: -1000
    max: 1000
    step: 20
    value: 0
    handleSize: 0
    handleShape: 'square'
    circleShape: 'pie'
    startAngle: 315

  $('#speed-slider-3').roundSlider
    sliderType: 'min-range'
    showTooltip: true
    radius: 75
    width: 16
    min: -1000
    max: 1000
    step: 20
    value: 0
    handleSize: 0
    handleShape: 'square'
    circleShape: 'pie'
    startAngle: 315

  $('#speed-slider-4').roundSlider
    sliderType: 'min-range'
    showTooltip: true
    radius: 75
    width: 16
    min: -1000
    max: 1000
    step: 20
    value: 0
    handleSize: 0
    handleShape: 'square'
    circleShape: 'pie'
    startAngle: 315

  $('#power-slider-0').roundSlider
    sliderType: 'min-range'
    showTooltip: true
    radius: 75
    width: 16
    min: -100
    max: 100
    step: 5
    value: 0
    handleSize: 0
    handleShape: 'square'
    circleShape: 'pie'
    startAngle: 315

  $('#power-slider-1').roundSlider
    sliderType: 'min-range'
    showTooltip: true
    radius: 75
    width: 16
    min: -100
    max: 100
    step: 5
    value: 0
    handleSize: 0
    handleShape: 'square'
    circleShape: 'pie'
    startAngle: 315

  $('#power-slider-2').roundSlider
    sliderType: 'min-range'
    showTooltip: true
    radius: 75
    width: 16
    min: -100
    max: 100
    step: 5
    value: 0
    handleSize: 0
    handleShape: 'square'
    circleShape: 'pie'
    startAngle: 315

  $('#power-slider-3').roundSlider
    sliderType: 'min-range'
    showTooltip: true
    radius: 75
    width: 16
    min: -100
    max: 100
    step: 5
    value: 0
    handleSize: 0
    handleShape: 'square'
    circleShape: 'pie'
    startAngle: 315

  $('#power-slider-4').roundSlider
    sliderType: 'min-range'
    showTooltip: true
    radius: 75
    width: 16
    min: -100
    max: 100
    step: 5
    value: 0
    handleSize: 0
    handleShape: 'square'
    circleShape: 'pie'
    startAngle: 315

  $scope.direction_multipliers = [0, 1, -1, 0]

  $interval((->
    $http.get('/api/motors', {}).success (data, status, headers, config) ->
      for motor in $scope.motors
        m = data.motor_state[motor.i]
        mul = $scope.direction_multipliers[m.direction]
        motor.power = mul * m.power
        motor.speed = mul * m.goal_velocity
        motor.position = m.goal_position
  ), 500)

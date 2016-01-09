exports.name = 'MotorsViewController'

exports.inject = (app) ->
  app.controller exports.name, [
    '$scope'
    '$http'
    '$interval'
    '$timeout'
    exports.controller
  ]
  return

exports.controller = ($scope, $http, $interval, $timeout) ->

  set_speed = (motor, event) ->
    $scope.$apply ->
      motor.speed = event.value

      # Emit event here

  set_power = (motor, event) ->
    $scope.$apply ->
      motor.power = event.value

      # Emit event here

  $scope.clear_position = (motor) ->
    motor.position = 0

    # Emit event here

  $scope.stop_motor = (motor) ->
    motor.speed = 0
    motor.power = 0

    update_slider motor

    # Emit event here

  update_slider = (motor) ->
    console.log motor.power_slider
    motor.power_slider.setValue(motor.power)
    motor.speed_slider.setValue(motor.speed)
    

  $scope.motors = 
    for i in [0...4]
      {
        name: "Motor #{i}"
        i: i
        speed: 0
        power: 0
        position: 0
        selected: false
        action: 'speed'

        power_slider: null
        speed_slider: null
      }

  $scope.selected_motor = $scope.motors[0]

  $scope.select_motor = (motor) ->
    $scope.selected_motor = motor

  $timeout (->

    # init the speed sliders
    for i in [0...4]
       $scope.motors[i].speed_slider = $('#speed-slider-' + i).roundSlider
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
        change: set_speed.bind(undefined, $scope.motors[i])

    # init the power sliders
    for i in [0...4]
      $scope.motors[i].power_slider = $('#power-slider-' + i).roundSlider
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
        change: set_power.bind(undefined, $scope.motors[i])
  ), 100

  direction_multipliers = [0, 1, -1, 0]

  $interval((->
    $http.get('/api/motors', {}).success (data, status, headers, config) ->

      if 'motor_state' not in data
        return

      for motor in $scope.motors
        m = data.motor_state[motor.i]
        mul = $scope.direction_multipliers[m.direction]
        motor.power = mul * m.power
        motor.speed = mul * m.goal_velocity
        motor.position = m.goal_position

        update_slider(motor)
  ), 500)

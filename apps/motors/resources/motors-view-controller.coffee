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

  $scope.clear_position = (motor) ->
    motor.position = 0

    # Emit event here

  $scope.stop_motor = (motor) ->
    motor.speed = 0
    motor.power = 0
    $http.post('/api/motors', {port: motor.i, stop: true})

    # Emit event here

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

  $scope.on_speed_slider_click = (motor) ->
    direction = Math.sign(motor.speed)
    direction = 2 if direction is -1

    $http.post('/api/motors',
      port: motor.i
      mode: 1
      direction: direction
      power: Math.abs(motor.speed)
    )

  $scope.on_power_slider_click = (motor) ->
    direction = Math.sign(motor.power)
    direction = 2 if direction is -1

    $http.post('/api/motors', 
      port: motor.i
      mode: 0
      direction: direction
      power: Math.abs(motor.power)
    )

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
  ), 500)

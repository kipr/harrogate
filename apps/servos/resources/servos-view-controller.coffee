exports.name = 'ServosViewController'

exports.inject = (app) ->
  app.controller exports.name, [
    '$scope'
    '$http'
    '$interval'
    '$timeout'
    '$window'
    exports.controller
  ]
  return

exports.controller = ($scope, $http, $interval, $timeout, $window) ->

  $scope.servos = 
    for i in [0...4]
      {
        name: "Servo #{i}"
        i: i
        position: 0
        enabled: false
      }

  $scope.selected_servo = $scope.servos[0]

  $scope.select_servo = (servo) ->
    $scope.selected_servo = servo

  $scope.on_slider_click = (servo) ->

  $scope.enable_servo = (servo, enable) ->
    servo.enabled = enable
    $http.post('/api/servos', {port: servo.i, position: servo.position, enabled: servo.enabled })

  $scope.on_slider_click = (servo) ->
    $http.post('/api/servos', {port: servo.i, position: servo.position, enabled: servo.enabled })

#  $interval((->
#    $http.get('/api/servos', {}).success (data, status, headers, config) ->
#
#      # TODO: Check if we got valid data
#      # if 'motor_state' not in data
#      #   return
#
#      for servo in $scope.servos
#
#
#        # TODO: set servo position
#        # m = data.motor_state[motor.i]
#        # mul = $scope.direction_multipliers[m.direction]
#        # motor.power = mul * m.power
#        # motor.speed = mul * m.goal_velocity
#        # motor.position = m.goal_position
#
#        update_slider(servo)
#  ), 500)


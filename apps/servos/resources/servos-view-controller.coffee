exports.name = 'ServosViewController'

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

  set_position = (servo, event) ->
    $scope.$apply ->
      servo.position = event.value

      # Emit event here

  update_slider = (servo) ->
    console.log servo.position_slider
    servo.position_slider.setValue(servo.position)

  $scope.servos = 
    for i in [0...4]
      {
        name: "Servo #{i}"
        i: i
        position: 0
        started: false

        position_slider: null
      }

  $scope.selected_servo = $scope.servos[0]

  $scope.select_servo = (servo) ->
    $scope.selected_servo = servo


  $timeout (->

    # init the position sliders
    for i in [0...4]
      console.log 'position-slider-' + i
      $scope.servos[i].position_slider = $('position-slider-' + i).roundSlider
        sliderType: 'min-range'
        showTooltip: true
        radius: 75
        width: 16
        min: 0
        max: 2047
        step: 16
        value: 0
        handleSize: 0
        handleShape: 'square'
        circleShape: 'pie'
        startAngle: 315

        change: set_position.bind(undefined, $scope.servos[i])
  ), 100

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


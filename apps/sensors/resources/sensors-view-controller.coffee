exports.name = 'SensorsViewController'

exports.inject = (app) ->
  app.controller exports.name, [
    '$scope'
    '$http'
    '$interval'
    exports.controller
  ]
  return

exports.controller = ($scope, $http, $interval) ->

  $scope.show_graph_view = true

  history_depth = 20

  $scope.toggle_show_graph = (sensor) ->
    sensor.show_graph = not sensor.show_graph

  $scope.chartOptions =
    high: 1400
    low: 0
    showPoint: false
    lineSmooth: false

  $scope.show_graph = false
  $scope.barData =
                labels: ['-20 s', '', '', '', '', '', '', '', '', '',
                         '-10 s', '', '', '', '', '', '', '', '', 'now']
                series: []

  update_bar_data = ->
    $scope.show_graph = false
    $scope.barData.series.length = 0
    for sensor in $scope.sensors
      if sensor.show_graph
        $scope.barData.series.push sensor.history

    if $scope.barData.series.length
      $scope.show_graph = true

  generate_sensors = ->
    sensors = []
    for i in [0...6]
      sensors.push {
        name: "Analog Sensor #{i}"
        value: 0
        history: (0 for [1..history_depth])
        show_graph: false
        type: 'analog'
        i: i}
    for i in [0...10]
      sensors.push {
        name: "Digital Sensor #{i}"
        value: 0
        history: (0 for [1..history_depth])
        show_graph: false
        type: 'digital'
        i: i}
    sensors.push
      name: "Accelerometer X"
      value: 0
      history: (0 for [1..history_depth])
      show_graph: false
      type: 'imu_accel_x'
      i: 0
    sensors.push
      name: "Accelerometer Y"
      value: 0
      history: (0 for [1..history_depth])
      show_graph: false
      type: 'imu_accel_y'
      i: 0
    sensors.push
      name: "Accelerometer Z"
      value: 0
      history: (0 for [1..history_depth])
      show_graph: false
      type: 'imu_accel_z'
      i: 0
    sensors.push
      name: "Magnetometer X"
      value: 0
      history: (0 for [1..history_depth])
      show_graph: false
      type: 'imu_accel_x'
      i: 0
    sensors.push
      name: "Magnetometer Y"
      value: 0
      history: (0 for [1..history_depth])
      show_graph: false
      type: 'imu_magneto_y'
      i: 0
    sensors.push
      name: "Magnetometer Z"
      value: 0
      history: (0 for [1..history_depth])
      show_graph: false
      type: 'imu_magneto_z'
      i: 0
    sensors.push
      name: "Gyroscope X"
      value: 0
      history: (0 for [1..history_depth])
      show_graph: false
      type: 'imu_gyro_x'
      i: 0
    sensors.push
      name: "Gyroscope Y"
      value: 0
      history: (0 for [1..history_depth])
      show_graph: false
      type: 'imu_gyro_y'
      i: 0
    sensors.push
      name: "Gyroscope Z"
      value: 0
      history: (0 for [1..history_depth])
      show_graph: false
      type: 'imu_gyro_z'
      i: 0
    return sensors

  $scope.sensors = generate_sensors()

  $interval(( ->
    $http.get('/api/sensors', {}).success (data, status, headers, config) ->
      console.log data
      for sensor in $scope.sensors
        value = sensor.value
        if sensor.type is 'analog'
          value = data.analogs.values[sensor.i]
        else if sensor.type is 'digital'
          value = data.digitals.values[sensor.i]
        else if sensor.type is 'imu_accel_x'
          value = data.imu.accel_state.x
        else if sensor.type is 'imu_accel_y'
          value = data.imu.accel_state.y
        else if sensor.type is 'imu_accel_z'
          value = data.imu.magneto_state.z
        else if sensor.type is 'imu_mag_x'
          value = data.imu.magneto_state.x
        else if sensor.type is 'imu_mag_y'
          value = data.imu.magneto_state.y
        else if sensor.type is 'imu_mag_z'
          value = data.imu.magneto_state.z
        else if sensor.type is 'imu_gyro_x'
          value = data.imu.gyro_state.x
        else if sensor.type is 'imu_gyro_y'
          value = data.imu.gyro_state.y
        else if sensor.type is 'imu_gyro_z'
          value = data.imu.gyro_state.z
          
        sensor.value = value
        sensor.history.shift()
        sensor.history.push value

    update_bar_data()
    ), 500)

  
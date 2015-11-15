exports.name = 'SensorsViewController'

exports.inject = (app) ->
  app.controller exports.name, [
    '$scope'
    '$interval'
    exports.controller
  ]
  return

exports.controller = ($scope, $interval) ->

  history_depth = 20

  $scope.toggle_show_graph = (sensor) ->
    sensor.show_graph = not sensor.show_graph

  $scope.toggle_pull_up = (sensor) ->
    sensor.pull_up = not sensor.pull_up

  $scope.chartOptions =
    high: 1400
    low: 0
    showPoint: false
    lineSmooth: false

  $scope.showGraph = false
  $scope.barData =
                labels: ['-20 s', '', '', '', '', '', '', '', '', '', '-10 s', '', '', '', '', '', '', '', '', 'now']
                series: []

  update_bar_data = ->
    $scope.showGraph = false
    $scope.barData.series.length = 0
    for sensor in $scope.sensors
      if sensor.show_graph
        $scope.barData.series.push sensor.history

    if $scope.barData.series.length
      $scope.showGraph = true

  generate_sensors = ->
    sensors = []
    for i in [0...7]
      sensors.push {
        name: "Analog Sensor #{i}"
        value: Math.round(Math.random()*1400)
        history: (0 for [1..history_depth])
        show_graph: false
        type: 'analog'
        pull_up: false}
    for i in [8...15]
      sensors.push {
        name: "Digital Sensor #{i}"
        value: Math.round Math.random()
        history: (0 for [1..history_depth])
        show_graph: false
        type: 'digital'}
    return sensors

  $scope.sensors = generate_sensors()

  $interval(( ->
    for sensor in $scope.sensors
      value = sensor.value

      if sensor.type is 'analog'
        value += Math.round(Math.random()*20) - 10
        value = 0 if value < 0
        value = 1400 if value > 1400
      else
        value = Math.round Math.random()

      sensor.value = value
      sensor.history.shift()
      if sensor.type is 'digital'
        value *= 1400
      sensor.history.push value

    update_bar_data()

    ), 1000)

  
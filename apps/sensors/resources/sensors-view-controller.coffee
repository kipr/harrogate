exports.name = 'SensorsViewController'

exports.inject = (app) ->
  app.controller exports.name, [
    '$scope'
    '$interval'
    exports.controller
  ]
  return

exports.controller = ($scope, $interval) ->

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
                labels: ['-20 s', '', '', '', '', '', '', '', '', '', '-10 s', '', '', '', '', '', '', '', '', 'now']
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
        value: Math.round(Math.random()*1400)
        history: (0 for [1..history_depth])
        show_graph: false
        type: 'analog'}
    for i in [0...10]
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

  
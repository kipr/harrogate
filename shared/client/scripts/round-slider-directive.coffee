angular = require 'angular'

exports.name = 'roundSlider'

exports.inject = (app) ->
  app.directive exports.name, [
    exports.directive
  ]
  return

exports.directive = ->
  return {
    restrict: 'E'
    template: '<canvas/>'
    replace: true
    scope: {
      minValue: '@'
      maxValue: '@'
      value: '='
      onClick: '&?'
    }

    link: ($scope, $element, $attrs) ->
      canvas = $element[0]
      min_value = parseInt $scope.minValue
      max_value = parseInt $scope.maxValue

      draw_slider = ->
        canvas_container = canvas.parentElement

        context = canvas.getContext '2d'
        context.canvas.width  = canvas_container.offsetWidth
        context.canvas.height = canvas_container.offsetHeight

        width = canvas.offsetWidth
        height = canvas.offsetHeight
        [center_x, center_y] = [width/2, height/2]
        line_width = 30
        radius = (Math.min(width, height) - line_width)/2
        start_angle = 0.8 * Math.PI
        end_angle = 2.2 * Math.PI

        # the current value on the circle
        position_percentage = Math.abs($scope.value - min_value) / (max_value - min_value)

        max_value_angle = Math.PI - start_angle
        min_value_angle = Math.PI - end_angle

        current_position_angle = min_value_angle + (max_value_angle - min_value_angle) * position_percentage
        value_on_circle_x = center_x + (radius + line_width/2) * Math.cos(current_position_angle)
        value_on_circle_y = center_y + (radius + line_width/2) * Math.sin(current_position_angle)

        # draw the arc
        context.beginPath()
        context.arc center_x, center_y, radius, start_angle, end_angle, false
        context.lineWidth = line_width
        context.strokeStyle = 'black'
        context.stroke()

        # draw the needle
        context.beginPath()
        context.moveTo center_x, center_y
        context.lineTo value_on_circle_x, value_on_circle_y
        context.strokeStyle = '#337ab7'
        context.lineWidth = 5
        context.stroke()

        # draw the center arc
        context.beginPath()
        context.arc center_x, center_y, 10, 0, 2*Math.PI, false
        context.fillStyle = 'black'
        context.fill()

        # draw the current value
        context.font = '30px Arial'
        context.textAlign = 'center'
        context.fillText $scope.value, center_x, height-30

        # set the position
        canvas.onmousedown = (e) ->
          [x, y] =
          if event.offsetX?
            [e.offsetX, e.offsetY]
          else
            [e.layerX - e.currentTarget.offsetLeft, e.layerY - e.currentTarget.offsetTop]

          # calculate the value from the x, y
          mouse_angle = Math.atan2(y - center_y, x - center_x)

          if mouse_angle > 0.2*Math.PI and mouse_angle <= 0.5*Math.PI
              # too much -> value = max
              new_position = max_value

          else if mouse_angle > 0.5*Math.PI and mouse_angle <= 0.8*Math.PI
              # too less -> value = min
              new_position = min_value

          else if mouse_angle >= 0.8*Math.PI
            # x < 0, y < 0
            new_position = (max_value - min_value) * (mouse_angle - 0.8*Math.PI) / (1.4*Math.PI)
            new_position += min_value

          else
            new_position = (max_value - min_value) * ((0.2*Math.PI + Math.PI + mouse_angle) / (1.4*Math.PI))
            new_position += min_value

          $scope.$apply ->
            $scope.value = Math.round new_position

          if $scope.onClick?
            $scope.onClick()

          draw_slider()

      draw_slider()
  }
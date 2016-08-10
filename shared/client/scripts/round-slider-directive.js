var angular;

angular = require('angular');

exports.name = 'roundSlider';

exports.inject = function(app) {
  app.directive(exports.name, [exports.directive]);
};

exports.directive = function() {
  return {
    restrict: 'E',
    template: '<canvas/>',
    replace: true,
    scope: {
      minValue: '@',
      maxValue: '@',
      value: '=',
      onClick: '&?'
    },
    link: function($scope, $element, $attrs) {
      var canvas, draw_slider, max_value, min_value;
      canvas = $element[0];
      min_value = parseInt($scope.minValue);
      max_value = parseInt($scope.maxValue);
      draw_slider = function() {
        var canvas_container, center_x, center_y, context, current_position_angle, end_angle, height, line_width, max_value_angle, min_value_angle, position_percentage, radius, ref, start_angle, value_on_circle_x, value_on_circle_y, width;
        canvas_container = canvas.parentElement;
        context = canvas.getContext('2d');
        context.canvas.width = canvas_container.offsetWidth;
        context.canvas.height = canvas_container.offsetHeight;
        width = canvas.offsetWidth;
        height = canvas.offsetHeight;
        ref = [width / 2, height / 2], center_x = ref[0], center_y = ref[1];
        line_width = 30;
        radius = (Math.min(width, height) - line_width) / 2;
        start_angle = 0.8 * Math.PI;
        end_angle = 2.2 * Math.PI;

        // the current value on the circle
        position_percentage = Math.abs($scope.value - min_value) / (max_value - min_value);
        max_value_angle = Math.PI - start_angle;
        min_value_angle = Math.PI - end_angle;
        current_position_angle = min_value_angle + (max_value_angle - min_value_angle) * position_percentage;
        value_on_circle_x = center_x + (radius + line_width / 2) * Math.cos(current_position_angle);
        value_on_circle_y = center_y + (radius + line_width / 2) * Math.sin(current_position_angle);

        // draw the arc
        context.beginPath();
        context.arc(center_x, center_y, radius, start_angle, end_angle, false);
        context.lineWidth = line_width;
        context.strokeStyle = 'black';
        context.stroke();

        // draw the needle
        context.beginPath();
        context.moveTo(center_x, center_y);
        context.lineTo(value_on_circle_x, value_on_circle_y);
        context.strokeStyle = '#337ab7';
        context.lineWidth = 5;
        context.stroke();

        // draw the center arc
        context.beginPath();
        context.arc(center_x, center_y, 10, 0, 2 * Math.PI, false);
        context.fillStyle = 'black';
        context.fill();

        // draw the current value
        context.font = '30px Arial';
        context.textAlign = 'center';
        context.fillText($scope.value, center_x, height - 30);

        // set the position
        return canvas.onmousedown = function(e) {
          var mouse_angle, new_position, ref1, x, y;
          ref1 = e.offsetX != null ? [e.offsetX, e.offsetY] : [e.layerX - e.currentTarget.offsetLeft, e.layerY - e.currentTarget.offsetTop], x = ref1[0], y = ref1[1];

          // calculate the value from the x, y
          mouse_angle = Math.atan2(y - center_y, x - center_x);
          if (mouse_angle > 0.2 * Math.PI && mouse_angle <= 0.5 * Math.PI) {
            // too much -> value = max
            new_position = max_value;
          } else if (mouse_angle > 0.5 * Math.PI && mouse_angle <= 0.8 * Math.PI) {
            // too less -> value = min
            new_position = min_value;
          } else if (mouse_angle >= 0.8 * Math.PI) {
            // x < 0, y < 0
            new_position = (max_value - min_value) * (mouse_angle - 0.8 * Math.PI) / (1.4 * Math.PI);
            new_position += min_value;
          } else {
            new_position = (max_value - min_value) * ((0.2 * Math.PI + Math.PI + mouse_angle) / (1.4 * Math.PI));
            new_position += min_value;
          }
          $scope.$apply(function() {
            return $scope.value = Math.round(new_position);
          });
          if ($scope.onClick != null) {
            $scope.onClick();
          }
          return draw_slider();
        };
      };
      return draw_slider();
    }
  };
};

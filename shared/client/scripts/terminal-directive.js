var angular, code_mirror;

angular = require('angular');

code_mirror = require('codemirror/lib/codemirror');

exports.name = 'terminal';

exports.inject = function(app) {
  app.directive(exports.name, [exports.directive]);
};

exports.directive = function() {
  return {
    restrict: 'E',
    template: '<textarea class="terminal-textarea"></textarea>',
    scope: {
      outputEvent: '@',
      inputEvent: '@',
      resetEvent: '@'
    },
    link: function($scope, $element, $attrs) {
      var editor, on_enter, read_only_ch, reset_mode;
      read_only_ch = -1;
      on_enter = function(e) {
        if ($scope.inputEvent != null) {
          $scope.$emit($scope.inputEvent, e.getLine(e.lastLine()).substring(read_only_ch + 1));
        }
        read_only_ch = -1;
        return code_mirror.Pass;
      };
      editor = code_mirror.fromTextArea($element.children()[0], {
        mode: 'text/plain',
        lineNumbers: false,
        theme: 'eclipse',
        viewportMargin: Infinity,
        extraKeys: {
          Enter: on_enter
        }
      });
      reset_mode = false;
      editor.on('beforeChange', function(e, obj) {
        if (reset_mode) {
          // allow changes if we are in reset_mode
          return;
        }
        if (obj.to.line !== e.lastLine()) {
          // allow only changes to the last line
          obj.cancel();
          return;
        }
        if (obj.from.ch <= read_only_ch) {
          // and only after read_only_ch
          obj.cancel();
          return;
        }
      });
      if ($scope.outputEvent != null) {
        $scope.$on($scope.outputEvent, function(event, text) {
          editor.replaceRange(text, code_mirror.Pos(editor.lastLine()));
          editor.setCursor(editor.lineCount(), 0);
          read_only_ch = editor.getCursor().ch - 1;
        });
      }
      if ($scope.resetEvent != null) {
        $scope.$on($scope.resetEvent, function(event) {
          reset_mode = true;
          editor.setValue('');
          editor.setCursor(editor.lineCount(), 0);
          read_only_ch = editor.getCursor().ch - 1;
          reset_mode = false;
        });
      }
    }
  };
};

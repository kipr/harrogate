angular = require 'angular'
code_mirror = require 'codemirror/lib/codemirror'

exports.name = 'terminal'

exports.inject = (app) ->
  app.directive exports.name, [
    exports.directive
  ]
  return

exports.directive = ->
  return {
    restrict: 'E'
    template: '<textarea class="terminal-textarea"></textarea>'
    scope: {
      outputEvent: '@'
      inputEvent: '@'
      resetEvent: '@'
    }

    link: ($scope, $element, $attrs) ->
      read_only_ch = -1

      on_enter = (e) ->
        if $scope.inputEvent?
          $scope.$emit $scope.inputEvent, e.getLine(e.lastLine()).substring(read_only_ch + 1)
        read_only_ch = -1
        return code_mirror.Pass

      editor = code_mirror.fromTextArea($element.children()[0],
        mode: 'text/plain'
        lineNumbers: false
        theme: 'eclipse'
        viewportMargin: Infinity
        extraKeys:
          Enter: on_enter
      )

      reset_mode = false

      editor.on 'beforeChange', (e, obj) ->
        # allow changes if we are in reset_mode
        return if reset_mode

        # allow only changes to the last line
        if obj.to.line isnt e.lastLine()
          obj.cancel()
          return
        # and only after read_only_ch
        if obj.from.ch <= read_only_ch
          obj.cancel()
          return
        return

      if $scope.outputEvent?
        $scope.$on $scope.outputEvent, (event, text) ->
          editor.replaceRange text, code_mirror.Pos(editor.lastLine())
          editor.setCursor editor.lineCount(), 0
          read_only_ch = editor.getCursor().ch - 1
          return

      if $scope.resetEvent?
        $scope.$on $scope.resetEvent, (event) ->
          reset_mode = true
          editor.setValue ''
          editor.setCursor editor.lineCount(), 0
          read_only_ch = editor.getCursor().ch - 1
          reset_mode = false
          return

      return

    }

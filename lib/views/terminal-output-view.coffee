{$, ScrollView} = require 'atom-space-pen-views'

module.exports =
class TerminalOutputview extends ScrollView
    message: ''

    @content: ->
      @div class: 'django-test-runner', =>
        @div class: 'django-test-runner__test-output'

    addLine: (line) ->
      @find(".django-test-runner__test-output").append("<p>" + line + "</p>")

    reset: ->
      @find(".django-test-runner__test-output").empty()

    getURI: -> 'atom://django-test-runner:output'

    destroy: ->
      @panel?.destroy()

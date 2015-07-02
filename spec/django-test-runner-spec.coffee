DjangoTestRunner = require '../lib/django-test-runner'
cpp = require 'child-process-promise'
view = require '../lib/views/terminal-output-view'

# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

getWorkspace = ->
  return atom.workspace.paneForURI('atom://django-test-runner:output')

describe "DjangoTestRunner", ->
  beforeEach ->
    waitsForPromise ->
      atom.workspace.open('sample.js')
    waitsForPromise ->
      atom.packages.activatePackage('django-test-runner')

  it "should fail nicely if no manage.py is found", ->
    runs ->
      DjangoTestRunner.runTests()

    waitsFor ->
      getWorkspace()

    runs ->
      workspace = getWorkspace()
      expect(workspace.activeItem[0].innerText).toEqual("unable to find manage.py")

  it "should use the python executable in the settings", ->
    spyOn(DjangoTestRunner, 'getManageCommand').andCallFake ->
      result = "/User/somone/something/manage.py"
      {
        then: (callback, unused) ->
          callback result
      }
    spyOn(cpp, 'exec').andCallFake ->
      result =
        stdout: "Creating test database"
        stderr: "tests failed"
      {
        fail: (callback) ->
          # should never be called
        done: (callback) ->
          callback result
      }

    runs ->
      DjangoTestRunner.runTests()

    waitsFor ->
      workspace = getWorkspace()
      workspace and workspace.activeItem[0].innerText.indexOf("test")

    runs ->
      expect(DjangoTestRunner.getManageCommand).toHaveBeenCalled()
      expect(cpp.exec).toHaveBeenCalled()
      expectedOutput = '<div class="django-test-runner__test-output"><p>looking for management command..</p><p>running</p><p>python manage.py test</p><p>Creating test database</p><p>tests failed</p></div>'
      workspace = getWorkspace()
      expect(workspace.activeItem[0].innerHTML).toEqual(expectedOutput)

cpp = require 'child-process-promise'
path = require 'path'
temp = require 'temp'
fs = require 'fs'
{Point} = require 'atom'
DjangoTestRunner = require '../lib/django-test-runner'
view = require '../lib/views/terminal-output-view'

# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

getWorkspace = ->
  return atom.workspace.paneForURI('atom://django-test-runner:output')

describe "DjangoTestRunne", ->
  describe "gets the correct class method", ->
    [buffer, editor, filePath] = []

    beforeEach ->
      directory = temp.mkdirSync()
      atom.project.setPaths(directory)
      filePath = path.join(directory, 'example-test.py')
      fs.writeFileSync(filePath, '')

      waitsForPromise ->
        atom.workspace.open(filePath).then (e) -> editor = e

      runs ->
        buffer = editor.getBuffer()

      waitsForPromise ->
        atom.packages.activatePackage('language-python')

      runs ->
        txt = """
          from django.test import TestCase

          class SomeOtherTest(TestCase):
          	def testthings(self):
          		pass

          class SomeTest(TestCase):
          	def testOneThing(self):
          		pass

          	def testSomthing(self):
          		def annonymous_inner_function(self):
          			return 3
          		self.fail()

          	def testAFinalFunction(self):
          		self.fail()
        """
        buffer.setText(txt)

    it "it should get the correct return on the last line of a method", ->
      position = Point(13, 1)
      editor.setCursorBufferPosition(position)
      result = DjangoTestRunner.constructClassFunctionPath()
      expect(result).toEqual('SomeTest.testSomthing')

    it "it should get the outer method on an nested method", ->
      position = Point(12, 1)
      editor.setCursorBufferPosition(position)
      result = DjangoTestRunner.constructClassFunctionPath()
      expect(result).toEqual('SomeTest.testSomthing')

      position = Point(11, 1)
      editor.setCursorBufferPosition(position)
      result = DjangoTestRunner.constructClassFunctionPath()
      expect(result).toEqual('SomeTest.testSomthing')

    it "it should get the method on the method itself", ->
        position = Point(10, 1)
        editor.setCursorBufferPosition(position)
        result = DjangoTestRunner.constructClassFunctionPath()
        expect(result).toEqual('SomeTest.testSomthing')

    it "it should only return the class on the class", ->
        position = Point(6, 1)
        editor.setCursorBufferPosition(position)
        result = DjangoTestRunner.constructClassFunctionPath()
        expect(result).toEqual('SomeTest')

    it "it should return nothing on nothing", ->
        position = Point(5, 1)
        editor.setCursorBufferPosition(position)
        result = DjangoTestRunner.constructClassFunctionPath()
        expect(result).toEqual(null)

  describe "displays to the terminal window", ->
    beforeEach ->
      waitsForPromise ->
        atom.workspace.open('sample.js')
      waitsForPromise ->
        atom.packages.activatePackage('django-test-runner')

    it "should fail nicely if no manage.py is found", ->
      runs ->
        DjangoTestRunner.runTests()

      waitsFor ->
        workspace = getWorkspace()
        workspace and workspace.activeItem[0].innerText.includes("unable to find manage.py")

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
        workspace and workspace.activeItem[0].innerText.includes("test")

      runs ->
        expect(DjangoTestRunner.getManageCommand).toHaveBeenCalled()
        expect(cpp.exec).toHaveBeenCalled()
        expectedOutput = '<div class="django-test-runner__test-output"><p>looking for management command..</p><p>running</p><p>python manage.py test</p><p>Creating test database</p><p>tests failed</p></div>'
        workspace = getWorkspace()
        expect(workspace.activeItem[0].innerHTML).toEqual(expectedOutput)

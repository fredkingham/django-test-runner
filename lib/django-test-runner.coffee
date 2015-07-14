TerminalOutputView = require './views/terminal-output-view'
dir = require 'node-dir'
path = require 'path'
cpp = require 'child-process-promise'
q = require 'q'
python_exec = "python"
test_args = ""
ViewUri = 'atom://django-test-runner:output'
{CompositeDisposable} = require 'atom'
MANAGEPY =  "manage.py"
TESTPY = "tests.py"


module.exports = DjangoTestRunner =
  subscriptions: null
  editor: null

  # add a custom python path
  config:
    pythonExecutable:
      type: 'string'
      description: 'custom python executable (for virtualenv etc)'
      default: 'python'

  activate: (state) ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace', 'django-test-runner:run-all-tests': => @runTests()
    @subscriptions.add atom.commands.add 'atom-workspace', 'django-test-runner:run-this-method': =>
      @runTests(onlyApp=false, onlyThisTest=true)
    @subscriptions.add atom.commands.add 'atom-workspace', 'django-test-runner:run-this-app': =>
      @runTests(onlyApp=true, onlyThisTest=false)

    atom.workspace.addOpener (filePath) ->
      new TerminalOutputView() if filePath is ViewUri

  deactivate: ->
    @subscriptions.dispose()

  getCommand: (additionalParameters) ->
    pythonExec = atom.config.get('django-test-runner.pythonExecutable')
    runCommand = pythonExec + " manage.py test"
    if additionalParameters
      return runCommand + " " + additionalParameters
    else
      return runCommand

  getManageCommand: ->
    # get the first management command we can find
    project_paths = atom.project.getPaths()
    promises = []

    for project_path in project_paths
      deferred = q.defer()
      promises.push(deferred.promise)
      dir.files project_path, (err, files) ->
        if err
          deferred.reject err
        manageFiles = files.filter (file) ->
          path.basename(file) is MANAGEPY
        if manageFiles.length
          deferred.resolve(manageFiles[0])
        else
          deferred.reject "unable to find manage.py in " + project_path
    return q.any(promises)

  runCommand: (manage, terminalOutputView, command) ->
    terminalOutputView.addLine("running")
    terminalOutputView.addLine(command)
    options = "cwd": path.dirname(manage)
    childProcess = cpp.exec command, options
    viewResults = (result) ->
      terminalOutputView.addLine(result.stdout)
      terminalOutputView.addLine(result.stderr)
    childProcess.done viewResults
    childProcess.fail viewResults

  calcFileRoute: (manage, withModule=false) ->
    routeDir = path.dirname(manage)
    fileRoute = @editor.getPath()

    if fileRoute and path.basename(fileRoute) == TESTPY
      if fileRoute.includes(routeDir)
        if withModule
          # remove the .py suffix
          relativePath = fileRoute.slice(0, -3)
        else
          relativePath = path.dirname(fileRoute)
        relativePath = relativePath.replace(routeDir + path.sep, "")
        relativePath = relativePath.replace(path.sep, ".")
        return relativePath
    throw "unable to calculate file path"

  constructClassFunctionPath: ->
    cursor = @editor.cursors[0]
    spacingRegex = /(^\s*).*/
    classRegex = /(^\s*)class (\w+)/
    methodRegex = /(^\s*)def (\w+)/

    startLine = cursor.getCurrentBufferLine()
    currentSpacing = spacingRegex.exec(startLine)[1].length
    currentRowNum = cursor.getBufferRow()

    numberIterator = currentRowNum

    testMethod = methodRegex.exec(startLine)?[2]
    testClass = classRegex.exec(startLine)?[2]

    while numberIterator and currentSpacing
      numberIterator--
      currentLine = @editor.lineTextForBufferRow(numberIterator)
      method = methodRegex.exec(currentLine)

      if method
        lineSpacing = method[1].length
        if lineSpacing < currentSpacing
          currentSpacing = lineSpacing
          testMethod = method[2]

      someClass = classRegex.exec(currentLine)

      if someClass
        lineSpacing = someClass[1].length
        if lineSpacing < currentSpacing
          currentSpacing = lineSpacing
          testClass = someClass[2]

    if !testClass
      return null

    if !testMethod
      return testClass

    return testClass + "." + testMethod

  runTests: (onlyApp=false, onlyThisTest=false) ->
    potentialEditor = atom.workspace.getActiveTextEditor()

    if potentialEditor
      @editor = potentialEditor

    atom.workspace.open(ViewUri).done (terminalOutputView) =>
      terminalOutputView.addLine("looking for management command..")
      @getManageCommand().then (manage) =>
        try
          if onlyThisTest
            additionalParameters = @calcFileRoute(manage, withModule=true)
            additionalParameters = additionalParameters + ":" + @constructClassFunctionPath()
          else if onlyApp
            additionalParameters = @calcFileRoute(manage)
          else
            additionalParameters = null
          command = @getCommand(additionalParameters)
          @runCommand(manage, terminalOutputView, command)
        catch err
            terminalOutputView.addLine err;
      , (manage) ->
        terminalOutputView.addLine("unable to find manage.py")

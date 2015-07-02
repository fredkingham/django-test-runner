TerminalOutputView = require './views/terminal-output-view'
dir = require 'node-dir'
path = require 'path'
cpp = require 'child-process-promise'
q = require 'q'
python_exec = "python"
test_args = ""
ViewUri = 'atom://django-test-runner:output'
{CompositeDisposable} = require 'atom'
managepy = "manage.py"


module.exports = DjangoTestRunner =
  djangoTestRunnerView: null
  modalPanel: null
  subscriptions: null

  # add a custom python path
  config:
    pythonExecutable:
      type: 'string'
      description: 'custom python executable (for virtualenv etc)'
      default: 'python'

  activate: (state) ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace', 'django-test-runner:run-all-tests': => @runTests()
    atom.workspace.addOpener (filePath) ->
      new TerminalOutputView() if filePath is ViewUri

  deactivate: ->
    @subscriptions.dispose()

  getCommand: (python_exec, path) ->
    return python_exec + " " + path + " test"

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
          path.basename(file) is managepy
        if manageFiles.length
          deferred.resolve(manageFiles[0])
        else
          deferred.reject "unable to find manage.py in " + project_path
    return q.any(promises)

  runCommand: (manage, terminalOutputView) ->
    terminalOutputView.addLine("looking for management command..")
    managePromise = @getManageCommand()
    managePromise.then (manage) =>
      python_exec = atom.config.get('django-test-runner.pythonExecutable')
      command = @getCommand(python_exec, managepy)
      terminalOutputView.addLine("running")
      terminalOutputView.addLine(command)
      options = "cwd": path.dirname(manage)
      childProcess = cpp.exec command, options
      viewResults = (result) ->
        terminalOutputView.addLine(result.stdout)
        terminalOutputView.addLine(result.stderr)
      childProcess.done viewResults
      childProcess.fail viewResults

  runTests: ->
    atom.workspace.open(ViewUri).done (terminalOutputView) =>
      @getManageCommand().then (manage) =>
        @runCommand(manage, terminalOutputView)
      , (manage) ->
        terminalOutputView.addLine("unable to find manage.py")

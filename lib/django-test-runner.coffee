TerminalOutputView = require './views/terminal-output-view'
dir = require('node-dir')
path = require('path')
cp = require 'child_process'
q = require 'q'
python_exec = "python"
test_args = ""
ViewUri = 'atom://django-test-runner:output'
{CompositeDisposable} = require 'atom'


module.exports = DjangoTestRunner =
  djangoTestRunnerView: null
  modalPanel: null
  subscriptions: null

  activate: (state) ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace', 'django-test-runner:run-all-tests': => @runTests()
    atom.workspace.addOpener (filePath) ->
      new TerminalOutputView() if filePath is ViewUri

  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()

  serialize: ->
    djangoTestRunnerViewState: @terminalOutputView.serialize()

  getCommand: (python_exec, path)->
    return python_exec + " " + path + " test"

  getManageCommand: ->
    # get the first management command we can find
    deferred = q.defer();
    project_paths = atom.project.getPaths()
    for project_path in project_paths
        dir.files project_path, (err, files) ->
            if err
                raise err

            files.filter (file) ->
                if path.basename(file) is "manage.py"
                    # for the moment we're assuming only one manage.py
                    deferred.resolve file

    return deferred.promise

  runTests: ->
    @getManageCommand().done (manage) =>
        atom.workspace.open(ViewUri).done (terminalOutputView) =>
            command = @getCommand(python_exec, manage)
            options = "cwd": path.dirname(manage)
            cp.exec command, options, (error, stdout, stderr) =>
                terminalOutputView.addLine(stdout)
                terminalOutputView.addLine(stderr)

DjangoTestRunner = require '../lib/django-test-runner'

# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

describe "DjangoTestRunner", ->
  [workspaceElement, activationPromise] = []

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    activationPromise = atom.packages.activatePackage('django-test-runner')

  describe "when the django-test-runner:toggle event is triggered", ->
    it "hides and shows the modal panel", ->
      # Before the activation event the view is not on the DOM, and no panel
      # has been created
      expect(workspaceElement.querySelector('.django-test-runner')).not.toExist()

      # This is an activation event, triggering it will cause the package to be
      # activated.
      atom.commands.dispatch workspaceElement, 'django-test-runner:toggle'

      waitsForPromise ->
        activationPromise

      runs ->
        expect(workspaceElement.querySelector('.django-test-runner')).toExist()

        djangoTestRunnerElement = workspaceElement.querySelector('.django-test-runner')
        expect(djangoTestRunnerElement).toExist()

        djangoTestRunnerPanel = atom.workspace.panelForItem(djangoTestRunnerElement)
        expect(djangoTestRunnerPanel.isVisible()).toBe true
        atom.commands.dispatch workspaceElement, 'django-test-runner:toggle'
        expect(djangoTestRunnerPanel.isVisible()).toBe false

    it "hides and shows the view", ->
      # This test shows you an integration test testing at the view level.

      # Attaching the workspaceElement to the DOM is required to allow the
      # `toBeVisible()` matchers to work. Anything testing visibility or focus
      # requires that the workspaceElement is on the DOM. Tests that attach the
      # workspaceElement to the DOM are generally slower than those off DOM.
      jasmine.attachToDOM(workspaceElement)

      expect(workspaceElement.querySelector('.django-test-runner')).not.toExist()

      # This is an activation event, triggering it causes the package to be
      # activated.
      atom.commands.dispatch workspaceElement, 'django-test-runner:toggle'

      waitsForPromise ->
        activationPromise

      runs ->
        # Now we can test for view visibility
        djangoTestRunnerElement = workspaceElement.querySelector('.django-test-runner')
        expect(djangoTestRunnerElement).toBeVisible()
        atom.commands.dispatch workspaceElement, 'django-test-runner:toggle'
        expect(djangoTestRunnerElement).not.toBeVisible()

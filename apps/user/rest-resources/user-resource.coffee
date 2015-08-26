assert = require 'assert'
Q = require 'q'

AppCatalog = require_harrogate_module '/shared/scripts/app-catalog.coffee'
User = require_harrogate_module '/shared/scripts/user.coffee'

Directory = require AppCatalog.catalog['Host Filesystem'].path + '/directory.coffee'

AppManifest = require '../manifest.json'

class UserResource
  constructor: (@user) ->
    # fix me... assert(@user instanceof User)
    assert(@user.login?)
    @uri = AppManifest.web_api.users.uri + '/' + @user.login

  get_representation: (verbose = true) =>
    representation =
      login: @user.login
      links:
        self:
          href: @uri

    if not verbose
      # we are done
      return Q(representation)

    # get the preferences representation
    representation.preferences = {}

    # expose workspace preferences; wrap the path into a fs resource
    if @user.preferences?.workspace?.path?
      ws = Directory.create_from_path @user.preferences.workspace.path

      return ws.get_representation false
      .then (ws_representation) =>
        # Add the workspace representation
        representation.preferences.workspace = ws_representation

        return Q(representation)

    return Q(representation)

module.exports = UserResource
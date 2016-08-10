var AppCatalog, AppManifest, Directory, Q, User, UserResource, assert,
  bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

assert = require('assert');

Q = require('q');

AppCatalog = require_harrogate_module('/shared/scripts/app-catalog.js');

User = require_harrogate_module('/shared/scripts/user.js');

Directory = require(AppCatalog.catalog['Host Filesystem'].path + '/directory.js');

AppManifest = require('../manifest.json');

UserResource = (function() {
  function UserResource(user) {
    this.user = user;
    this.get_representation = bind(this.get_representation, this);
    // fix me... assert(@user instanceof User)
    assert(this.user.login != null);
    this.uri = AppManifest.web_api.users.uri + '/' + this.user.login;
  }

  UserResource.prototype.get_representation = function(verbose) {
    var ref, ref1, representation, ws;
    if (verbose == null) {
      verbose = true;
    }
    representation = {
      login: this.user.login,
      links: {
        self: {
          href: this.uri
        }
      }
    };
    if (!verbose) {
      // we are done
      return Q(representation);
    }

    // get the preferences representation
    representation.preferences = {};

    // expose workspace preferences; wrap the path into a fs resource
    if (((ref = this.user.preferences) != null ? (ref1 = ref.workspace) != null ? ref1.path : void 0 : void 0) != null) {
      ws = Directory.create_from_path(this.user.preferences.workspace.path);
      return ws.get_representation(false).then((function(_this) {
        return function(ws_representation) {
          // Add the workspace representation
          representation.preferences.workspace = ws_representation;
          return Q(representation);
        };
      })(this));
    }
    return Q(representation);
  };

  return UserResource;

})();

module.exports = UserResource;

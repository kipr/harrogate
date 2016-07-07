var AppCatalog, fs, path, url;

url = require('url');

fs = require('fs');

path = require('path');

AppCatalog = (function() {
  function AppCatalog() {
    var app, apps, data, i, len, manifest;
    this.catalog = {};
    this.apps_base_path = path.join(process.cwd(), 'apps');
    this.apps_nodejs_route_base = '/apps';
    this.apps_angularjs_route_base = '/apps';
    apps = fs.readdirSync(this.apps_base_path);
    for (i = 0, len = apps.length; i < len; i++) {
      app = apps[i];
      path = this.apps_base_path + "/" + app;
      if (!fs.statSync(path).isDirectory()) {
        continue;
      }
      data = fs.readFileSync(path + "/manifest.json", 'utf8');
      if (data == null) {
        console.log("Could not read " + path + "/manifest.json");
        continue;
      }
      manifest = JSON.parse(data);
      if (manifest == null) {
        console.log(path + "/manifest.json is malformed");
        continue;
      }

      // General app data
      if (manifest['name'] == null) {
        manifest['name'] = "" + app;
      }
      manifest['path'] = "" + path;
      if (manifest['description'] == null) {
        manifest['description'] = '';
      }

      // Bot UI data
      if (manifest['priority'] == null) {
        manifest['priority'] = 0;
      }
      if (manifest['hidden'] == null) {
        manifest['hidden'] = false;
      }
      if (manifest['fonticon'] == null) {
        manifest['fonticon'] = 'fa-exclamation-triangle';
      }
      if (manifest['category'] == null) {
        manifest['category'] = 'General';
      }

      // Server side data ('exec' is set)
      // manifest['init'] nothing to do
      if (manifest['exec'] != null) {
        manifest['exec_path'] = path + "/" + manifest['exec'];
        manifest['get_instance'] = function() {
          return require("" + this.exec_path);
        };
        // manifest['closing'] nothing to do
      }


      // Client view + angular controller ('angular_ctrl' is set)
      if (manifest['view'] == null) {
        console.log(manifest['name'] + ": Waring! manifest['view'] is not set");
      }
      if (manifest['view']) {
        manifest['url'] = "/#" + this.apps_angularjs_route_base + "/" + app;
        if (manifest['angular_ctrl'] != null) {
          manifest['angular_ctrl'] = path + "/" + manifest['angular_ctrl'];
        }
        manifest['angularjs_route'] = this.apps_angularjs_route_base + "/" + app;
        manifest['nodejs_route'] = this.apps_nodejs_route_base + "/" + app;
      } else {
        manifest['url'] = null;
        manifest['angular_ctrl'] = null;
        manifest['angularjs_route'] = null;
        manifest['nodejs_route'] = null;
      }

      // Web API data
      // manifest['web_api'] nothing to do
      this.catalog[manifest['name']] = manifest;
    }
  }

  AppCatalog.prototype.handle = function(request, response) {
    var callback;
    callback = url.parse(request.url, true).query['callback'];
    // should we return JSON or JSONP (callback defined)?
    if (callback != null) {
      response.writeHead(200, {
        'Content-Type': 'application/javascript'
      });
      return response.end(callback + "(" + (JSON.stringify(this.catalog)) + ")", 'utf8');
    } else {
      response.writeHead(200, {
        'Content-Type': 'application/json'
      });
      return response.end("" + (JSON.stringify(this.catalog)), 'utf8');
    }
  };

  return AppCatalog;

})();

module.exports = new AppCatalog;

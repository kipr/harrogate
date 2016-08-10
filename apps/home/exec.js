var app, app_catalog, app_categories, app_name, c, category_index, cats, i, j, k, len, ref, ref1;

app_catalog = require_harrogate_module('/shared/scripts/app-catalog.js');

cats = require('../categories.json');

app_categories = [];

category_index = function(name) {
  var i, j, ref;
  for (i = j = 0, ref = app_categories.length - 1; 0 <= ref ? j <= ref : j >= ref; i = 0 <= ref ? ++j : --j) {
    if (app_categories[i]['name'] === name) {
      return i;
    }
  }
  return -1;
};

for (j = 0, len = cats.length; j < len; j++) {
  c = cats[j];
  app_categories.push({
    name: c,
    list: []
  });
}

ref = app_catalog.catalog;
for (app_name in ref) {
  app = ref[app_name];
  // Skip hidden apps
  if (!app['hidden']) {
    c = app['category'];
    i = category_index(c);
    if (i < 0) {
      console.log("Warning: Please add " + c + " to categories.json");
      app_categories.push({
        name: c,
        list: []
      });
    }
    app_categories[i]['list'].push(app);
  }
}

// Sort the apps by priority
for (i = k = 0, ref1 = app_categories.length - 1; 0 <= ref1 ? k <= ref1 : k >= ref1; i = 0 <= ref1 ? ++k : --k) {
  app_categories[i]['list'].sort(function(a, b) {
    return a.priority - b.priority;
  });
}

module.exports = {
  exec: function() {},
  jade_locals: {
    apps: app_categories
  }
};

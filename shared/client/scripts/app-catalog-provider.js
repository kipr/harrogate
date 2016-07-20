// TODO: translation to javascript leads to O(n^2) below
var indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

exports.inject = function(app) {
  app.provider('AppCatalogProvider', exports.provider);
  return exports.provider;
};

exports.provider = function() {
  var app_catalog_url, app_categories_url;
  app_catalog_url = '/apps/catalog.json';
  app_categories_url = '/apps/categories.json';
  this.$get = [
    '$http', '$q', function($http, $q) {
      var service;
      service = {
        catalog: $q(function(resolve, reject) {
          $http.get(app_catalog_url).success(function(data, status, headers, config) {
            resolve(data);
          }).error(function(data, status, headers, config) {
            reject({
              status: status,
              data: data
            });
          });
        }),
        categories: $q(function(resolve, reject) {
          $http.get(app_categories_url).success(function(data, status, headers, config) {
            resolve(data);
          }).error(function(data, status, headers, config) {
            reject({
              status: status,
              data: data
            });
          });
        })
      };
      service.apps_by_category = $q(function(resolve, reject) {
        return $q.all([service.catalog, service.categories]).then(function(values) {
          var app, app_name, apps_by_category, cat, catalog, categories, i, len, ref, ref1;
          catalog = values[0];
          categories = values[1];
          apps_by_category = {};
          ref = categories != null ? categories : [];
          for (i = 0, len = ref.length; i < len; i++) {
            cat = ref[i];
            apps_by_category[cat] = [];
          }
          apps_by_category['Unknown'] = [];
          ref1 = catalog != null ? catalog : {};
          for (app_name in ref1) {
            app = ref1[app_name];
            if (app_name === "Home") {
              // store home app
              service.home_app = app;
            }
            cat = app['category'];
            if (indexOf.call(categories, cat) >= 0) {
              apps_by_category[cat].push(app);
            } else {
              apps_by_category['Unknown'].push(app);
            }
          }
          resolve(apps_by_category);
        });
      });
      return service;
    }
  ];
};

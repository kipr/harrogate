exports.inject = (app) ->
  app.provider 'AppCatalogProvider', exports.provider
  exports.provider

exports.provider = ->
  app_catalog_url = '/apps/catalog.json'
  app_categories_url = '/apps/categories.json'

  @$get = ['$http', '$q', ($http, $q) ->
    service =

      catalog: $q (resolve, reject) ->
        $http.get(app_catalog_url)
        .success (data, status, headers, config) ->
          resolve data
          return
        .error (data, status, headers, config) ->
          reject
            status: status
            data: data
          return
        return

      categories: $q (resolve, reject) ->
        $http.get(app_categories_url)
        .success (data, status, headers, config) ->
          resolve data
          return
        .error (data, status, headers, config) ->
          reject
            status: status
            data: data
          return
        return

    service.apps_by_category = $q (resolve, reject) ->
        $q.all [service.catalog, service.categories]
        .then (values) ->
          catalog = values[0]
          categories = values[1]

          apps_by_category = {}
          for cat in categories ? []
            apps_by_category[cat] = []

          apps_by_category['Unknown'] = []

          for app_name, app of catalog ? {}
            # store home app
            service.home_app = app if app_name is "Home"
            
            cat = app['category']
            if cat in categories
              apps_by_category[cat].push app
            else
              apps_by_category['Unknown'].push app

          resolve apps_by_category
          return

    service
  ]
  return
app_catalog = require_harrogate_module '/shared/scripts/app-catalog.coffee'

cats = require '../categories.json'

app_categories = []

category_index = (name) ->
  for i in [0 .. app_categories.length - 1]
    return i if app_categories[i]['name'] is name
  return -1

for c in cats
  app_categories.push
    name: c
    list: []
for app_name, app of app_catalog.catalog
  # Skip hidden apps
  if not app['hidden']
    c = app['category']
    i = category_index c
    if i < 0
      console.log "Warning: Please add #{c} to categories.json"
      app_categories.push
        name: c
        list: []
    app_categories[i]['list'].push app
      
# Sort the apps by priority
for i in [0 .. app_categories.length - 1]
  app_categories[i]['list'].sort (a, b) -> a.priority - b.priority

module.exports =

  exec: ->
    return

  jade_locals: {apps: app_categories}
gulp = require 'gulp'
jade = require 'gulp-jade'
coffee = require 'gulp-coffee'
minifyCSS = require 'gulp-minify-css'
gutil = require 'gulp-util'
nodemon = require 'gulp-nodemon'
rename = require 'gulp-rename'
data = require 'gulp-data'
path_tools = require 'path'

# Start the development server
gulp.task 'dev', [
  'shared'
  'apps'
  'watch'
], ->
  nodemon(
    script: 'server.js'
    watch: 'public'
    ext: 'html js json css'
  ).on 'restart', ->
    console.log 'restarted!'
    return
  return

# Create the shared static content
gulp.task 'shared', [
  'views'
  'styles'
  'resources'
  'scripts'
], ->

# Views task
gulp.task 'views', ->
  gulp.src('shared/client/views/*.jade')
  .pipe jade()
  .pipe gulp.dest('public/')
  return

# Styles task
gulp.task 'styles', ->
  gulp.src('shared/client/css/*.css')
  .pipe minifyCSS(keepBreaks: true)
  .pipe gulp.dest('public/css/')
  return

# Resources task
gulp.task 'resources', ->
  # Fonts
  gulp.src('shared/client/fonts/*')
  .pipe gulp.dest('public/fonts/')

  # images
  gulp.src('shared/client/images/*')
  .pipe gulp.dest('public/images/')

  # json data
  gulp.src('apps/categories.json')
  .pipe gulp.dest('public/apps/')
  return

# Scripts task
gulp.task 'scripts', ->
  gulp.src('shared/client/scripts/*.coffee')
  .pipe coffee(bare: true).on('error', gutil.log)
  .pipe gulp.dest('public/scripts/')

  # We will use browserify or something similar later for bootstrap, jQuery and angular
  gulp.src(['shared/client/scripts/lib/**/*'])
  .pipe gulp.dest('public/scripts/lib/')
  return

# Create the apps static content
gulp.task 'apps', [
  'app_views'
  'app_scripts'
], ->

# App views task
app_instances = {}
app_catalog = require './shared/scripts/app-catalog.coffee'
for app_name, app of app_catalog.catalog
  app_instances[path_tools.basename(app['path'])] = require app['exec_path']

gulp.task 'app_views', ->
  gulp.src('apps/**/resources/*.jade')
  .pipe data((file) ->
    # check if the app uses jade locals
    # there might be a bitter way....
    app_name = path_tools.basename(path_tools.dirname(path_tools.dirname(file.path)))

    if app_name of app_instances
      app_instance = app_instances[app_name]
      if app_instance['jade_locals']
        return app_instance['jade_locals']
    {}
  )
  .pipe jade().on('error', gutil.log)
  .pipe rename((path) ->
    path.dirname = path.dirname.replace '/resources', ''
    path.dirname = path.dirname.replace '\\resources', ''
    return
  )
  .pipe gulp.dest('public/apps/')
  return

# App scripts task
gulp.task 'app_scripts', ->
  gulp.src('apps/**/resources/*.coffee')
  .pipe coffee(bare: true).on('error', gutil.log)
  .pipe rename((path) ->
    path.dirname = path.dirname.replace '/resources', '/scripts'
    path.dirname = path.dirname.replace '\\resources', '\\scripts'
    return
  )
  .pipe gulp.dest('public/apps/')
  return

# Watch task
gulp.task 'watch', ->
  gulp.watch 'shared/client/views/*.jade', ['views']
  gulp.watch 'shared/client/css/*.css', ['styles']
  gulp.watch 'shared/client/fonts/*', ['resources']
  gulp.watch 'shared/client/images/*', ['resources']
  gulp.watch 'apps/categories.json', ['resources']
  gulp.watch 'shared/client/scripts/*.coffee', ['scripts']

  gulp.watch 'apps/**/resources/*.jade', ['app_views']
  gulp.watch 'apps/**/resources/*.coffee', ['app_scripts']
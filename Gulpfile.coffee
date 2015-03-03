browserify = require 'browserify'
coffee_script = require 'coffee-script'
coffee = require 'gulp-coffee'
data = require 'gulp-data'
gulp = require 'gulp'
gulp_filter = require 'gulp-filter'
gutil = require 'gulp-util'
jade = require 'gulp-jade'
minifyCSS = require 'gulp-minify-css'
nodemon = require 'gulp-nodemon'
path_tools = require 'path'
rename = require 'gulp-rename'
transform = require 'vinyl-transform'
through = require 'through'

# Default task
gulp.task 'default', ['dev'] 

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
  'shared_views'
  'shared_styles'
  'shared_resources'
  'shared_scripts'
  'shared_3rd_party_libs'
], ->

# Shared views task
gulp.task 'shared_views', ->
  gulp.src('shared/client/views/*.jade')
  .pipe jade()
  .pipe gulp.dest('public/')

# Shared styles task
gulp.task 'shared_styles', ->
  gulp.src('shared/client/css/*.css')
  .pipe minifyCSS(keepBreaks: true)
  .pipe gulp.dest('public/css/')

# Shared resources task
gulp.task 'shared_resources', ->
  gulp.src('apps/categories.json')
  .pipe gulp.dest('public/apps/')

# Shared resources task
gulp.task 'shared_3rd_party_libs', [
  'bootstrap'
  'jquery'
  'font-awesome'
], ->

# bootstrap
gulp.task 'bootstrap', ->
  gulp.src('node_modules/bootstrap/dist/**/*')
  .pipe rename((path) ->
    path.dirname = 'scripts' if path.dirname is 'js'
    return
  )
  .pipe gulp.dest('public/')

# jquery
gulp.task 'jquery', ->
  gulp.src('node_modules/jquery/dist/jquery.*')
  .pipe gulp.dest('public/scripts/')

# Font Awesome
gulp.task 'font-awesome', ->
  gulp.src('node_modules/font-awesome/**/*')
  .pipe gulp_filter ['css/*', 'fonts/*']
  .pipe gulp.dest('public/')

# Scripts task
gulp.task 'shared_scripts', ->
# Browserify task
  b = browserify
    debug: true
    bare: true
  .transform (file) ->
    data[file] = ''

    write = (buf) ->
      data[file] += buf
      return

    end = ->
      @queue coffee_script.compile(data[file])
      @queue null
      return

    through write, end

  # bundle the main app for index.jade
  gulp.src 'shared/client/scripts/harrogate-index-app.coffee'
  .pipe transform((filename) ->
    b.add filename
    b.bundle()
  )
  .pipe rename((path) ->
    path.extname  = '.js'
    return
  )
  .pipe gulp.dest 'public/scripts/'

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

# Watch task
gulp.task 'watch', ->
  gulp.watch 'shared/client/views/**/*.jade', ['shared_views']
  gulp.watch 'shared/client/css/*.css', ['shared_styles']
  gulp.watch 'shared/client/scripts/*.coffee', ['shared_scripts']

  gulp.watch 'apps/**/resources/**/*.jade', ['app_views']
  gulp.watch 'apps/**/resources/*.coffee', ['app_scripts']
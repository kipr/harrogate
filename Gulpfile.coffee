browserify = require 'browserify'
coffee = require 'coffee-script'
data = require 'gulp-data'
fs = require 'fs'
gulp = require 'gulp'
gulp_filter = require 'gulp-filter'
gutil = require 'gulp-util'
jade = require 'gulp-jade'
nodemon = require 'gulp-nodemon'
os = require 'os'
path_tools = require 'path'
rename = require 'gulp-rename'
request = require 'request'
transform = require 'vinyl-transform'
through = require 'through'

config = require './config.coffee'

# Add daylite, ... to the Windows path
if os.platform() is 'win32'
  process.env.PATH += path_tools.delimiter + "#{config.ext_deps.bin_path}"
else if os.platform() is 'darwin'
  process.env.DYLD_LIBRARY_PATH += path_tools.delimiter + "#{config.ext_deps.lib_path}"
else # Linux
  process.env.LD_LIBRARY_PATH += path_tools.delimiter + "#{config.ext_deps.lib_path}"

process.env.COMPILE = 1

# avoid require '../../.. ... for shared harrogate module
if not global.require_harrogate_module?
  global.require_harrogate_module = (module) ->
    require __dirname + '/' + module

# Create the app instances
app_instances = {}
app_catalog = require_harrogate_module '/shared/scripts/app-catalog.coffee'
for app_name, app of app_catalog.catalog
  app_instances[path_tools.basename(app['path'])] = app.get_instance()

# Default task
gulp.task 'default', ['dev'] 

# Start the development server
gulp.task 'dev', [
  'compile'
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

# Create all
gulp.task 'compile', [
  'shared'
  'apps'
], ->

# Create the shared static content
gulp.task 'shared', [
  'shared_views'
  'shared_styles'
  'shared_resources'
  'scripts'
  'shared_3rd_party_libs'
], ->

# Shared views task
gulp.task 'shared_views', ->
  gulp.src('shared/client/views/*.jade')
  .pipe jade()
  .pipe gulp.dest('public/')

# Shared favicon task
gulp.task 'shared_favicon', ->
  gulp.src('shared/client/favicon/*')
  .pipe gulp.dest('public/favicon/')

# Shared styles task
gulp.task 'shared_styles', ->
  gulp.src('shared/client/css/*.css')
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
  'code-mirror'
  'code-mirror-themes'
  'angular-ui'
  'angular-chartist'
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

# Code Mirror
gulp.task 'code-mirror', ->
  gulp.src('node_modules/codemirror/lib/codemirror.css')
  .pipe gulp.dest('public/css/')

# Code Mirror Themes
gulp.task 'code-mirror-themes', ->
  gulp.src('node_modules/codemirror/theme/*.css')
  .pipe gulp.dest('public/css/codemirror-theme/')

# AngularUI
gulp.task 'angular-ui', [
  'scripts'
],  ->
  request('http://angular-ui.github.io/bootstrap/ui-bootstrap-tpls-0.13.0.min.js')
  .pipe fs.createWriteStream('public/scripts/ui-bootstrap-tpls.min.js')

# Angular Chartist
gulp.task 'angular-chartist', [
  'scripts'
  'chartist'
],  ->
  request('https://raw.githubusercontent.com/paradox41/angular-chartist.js/master/dist/angular-chartist.min.js')
  .pipe fs.createWriteStream('public/scripts/angular-chartist.min.js')

# Chartist
gulp.task 'chartist', [
  'chartist.js'
  'chartist.css'
], ->

gulp.task 'chartist.js', [
  'scripts'
],  ->
  request('https://raw.githubusercontent.com/gionkunz/chartist-js/master/dist/chartist.min.js')
  .pipe fs.createWriteStream('public/scripts/chartist.min.js')

gulp.task 'chartist.css',  ->
  request('https://raw.githubusercontent.com/gionkunz/chartist-js/master/dist/chartist.min.css')
  .pipe fs.createWriteStream('public/css/chartist.min.css')

# Scripts task
gulp.task 'scripts', ->
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
      @queue coffee.compile(data[file])
      @queue null
      return

    through write, end

  # Add app scripts
  for app_name, app of app_catalog.catalog
    if app.angular_ctrl?
      b.require app.angular_ctrl, expose: app.name
  
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
], ->

# App views task
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

# Watch task
gulp.task 'watch', ->
  gulp.watch 'shared/client/views/**/*.jade', ['shared_views']
  gulp.watch 'shared/client/css/*.css', ['shared_styles']
  gulp.watch 'shared/client/scripts/*.coffee', ['scripts']

  gulp.watch 'shared/client/views/templates/**/*.jade', ['app_views']
  gulp.watch 'apps/**/resources/**/*.jade', ['app_views']
  gulp.watch 'apps/**/resources/*.coffee', ['scripts']

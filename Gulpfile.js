var app, app_catalog, app_instances, app_name, browserify, config, data, fs, gulp, gulp_filter, gutil, jade, nodemon, os, path_tools, ref, rename, request, through, transform;

browserify = require('browserify');

data = require('gulp-data');

fs = require('fs');

gulp = require('gulp');

gulp_filter = require('gulp-filter');

gutil = require('gulp-util');

jade = require('gulp-jade');

nodemon = require('gulp-nodemon');

os = require('os');

path_tools = require('path');

rename = require('gulp-rename');

request = require('request');

transform = require('vinyl-transform');

through = require('through');

config = require('./config.js');

process.env.COMPILE = 1;

if (global.require_harrogate_module == null) {
  global.require_harrogate_module = function(module) {
    return require(__dirname + '/' + module);
  };
}

app_instances = {};

app_catalog = require_harrogate_module('/shared/scripts/app-catalog.js');

ref = app_catalog.catalog;
for (app_name in ref) {
  app = ref[app_name];
  app_instances[path_tools.basename(app['path'])] = app.get_instance();
}

gulp.task('default', ['dev']);

gulp.task('dev', ['compile', 'watch'], function() {
  nodemon({
    script: 'server.js',
    watch: 'public',
    ext: 'html js json css'
  }).on('restart', function() {
    console.log('restarted!');
  });
});

gulp.task('compile', ['shared', 'apps'], function() {});

gulp.task('shared', ['shared_views', 'shared_styles', 'shared_resources', 'scripts', 'shared_3rd_party_libs', 'doc'], function() {});

gulp.task('shared_views', function() {
  return gulp.src('shared/client/views/*.jade').pipe(jade()).pipe(gulp.dest('public/'));
});

gulp.task('shared_favicon', function() {
  return gulp.src('shared/client/favicon/*').pipe(gulp.dest('public/favicon/'));
});

gulp.task('shared_styles', function() {
  return gulp.src('shared/client/css/*.css').pipe(gulp.dest('public/css/'));
});

gulp.task('shared_resources', function() {
  return gulp.src('apps/categories.json').pipe(gulp.dest('public/apps/'));
});

gulp.task('shared_3rd_party_libs', ['bootstrap', 'jquery', 'font-awesome', 'code-mirror', 'code-mirror-themes', 'angular-ui'], function() {});

gulp.task('bootstrap', function() {
  return gulp.src('node_modules/bootstrap/dist/**/*').pipe(rename(function(path) {
    if (path.dirname === 'js') {
      path.dirname = 'scripts';
    }
  })).pipe(gulp.dest('public/'));
});

gulp.task('doc', function() {
  return gulp.src('shared/client/doc/**/*').pipe(gulp.dest('public/doc/'));
});

gulp.task('jquery', function() {
  return gulp.src('node_modules/jquery/dist/jquery.*').pipe(gulp.dest('public/scripts/'));
});

gulp.task('font-awesome', function() {
  return gulp.src('node_modules/font-awesome/**/*').pipe(gulp_filter(['css/*', 'fonts/*'])).pipe(gulp.dest('public/'));
});

gulp.task('code-mirror', function() {
  return gulp.src('node_modules/codemirror/lib/codemirror.css').pipe(gulp.dest('public/css/'));
});

gulp.task('code-mirror-themes', function() {
  return gulp.src('node_modules/codemirror/theme/*.css').pipe(gulp.dest('public/css/codemirror-theme/'));
});

gulp.task('angular-ui', ['scripts'], function() {
  return request('http://angular-ui.github.io/bootstrap/ui-bootstrap-tpls-0.13.0.min.js').pipe(fs.createWriteStream('public/scripts/ui-bootstrap-tpls.min.js'));
});



gulp.task('scripts', function() {
  var b, ref1;
  b = browserify({
    debug: true,
    bare: true
  }).transform(function(file) {
    var end, write;
    data[file] = '';
    write = function(buf) {
      data[file] += buf;
    };
    end = function() {
      this.queue(data[file]);
      this.queue(null);
    };
    return through(write, end);
  });
  ref1 = app_catalog.catalog;
  for (app_name in ref1) {
    app = ref1[app_name];
    if (app.angular_ctrl != null) {
      b.require(app.angular_ctrl, {
        expose: app.name
      });
    }
  }
  return gulp.src('shared/client/scripts/harrogate-index-app.js').pipe(transform(function(filename) {
    b.add(filename);
    return b.bundle();
  })).pipe(rename(function(path) {
    path.extname = '.js';
  })).pipe(gulp.dest('public/scripts/'));
});


gulp.task('apps', ['app_views'], function() {});

gulp.task('app_views', function() {
  return gulp.src('apps/**/resources/*.jade').pipe(data(function(file) {
    var app_instance;
    app_name = path_tools.basename(path_tools.dirname(path_tools.dirname(file.path)));
    if (app_name in app_instances) {
      app_instance = app_instances[app_name];
      if (app_instance['jade_locals']) {
        return app_instance['jade_locals'];
      }
    }
    return {};
  })).pipe(jade().on('error', gutil.log)).pipe(rename(function(path) {
    path.dirname = path.dirname.replace('/resources', '');
    path.dirname = path.dirname.replace('\\resources', '');
  })).pipe(gulp.dest('public/apps/'));
});

gulp.task('watch', function() {
  gulp.watch('shared/client/views/**/*.jade', ['shared_views']);
  gulp.watch('shared/client/css/*.css', ['shared_styles']);
  gulp.watch('shared/client/scripts/*.js', ['scripts']);
  gulp.watch('shared/client/views/templates/**/*.jade', ['app_views']);
  gulp.watch('apps/**/resources/**/*.jade', ['app_views']);
  return gulp.watch('apps/**/resources/*.js', ['scripts']);
});

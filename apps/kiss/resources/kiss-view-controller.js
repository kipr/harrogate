var code_mirror;

require('codemirror/mode/clike/clike');

code_mirror = require('codemirror/lib/codemirror');

exports.name = 'KissViewController';

exports.inject = function(app) {
  app.controller(exports.name, ['$scope', '$rootScope', '$location', '$http', '$timeout', 'AppCatalogProvider', 'ButtonsOnlyModalFactory', 'DownloadProjectModalFactory', 'FilenameModalFactory', exports.controller]);
};

exports.controller = function($scope, $rootScope, $location, $http, $timeout, AppCatalogProvider, ButtonsOnlyModalFactory, DownloadProjectModalFactory, FilenameModalFactory) {
  var compile, editor, onRouteChangeOff, on_window_beforeunload, save_file, saving;
  $scope.is_compiling = false;
  $scope.documentChanged = false;
  $scope.$on('$routeUpdate', function(next, current) {
    var ref, ref1;
    if ((((ref = $scope.displayed_file) != null ? ref.name : void 0) !== $location.search().file) || (((ref1 = $scope.selected_project) != null ? ref1.name : void 0) !== $location.search().project)) {
      return $scope.reload_ws();
    }
  });
  editor = code_mirror.fromTextArea(document.getElementById('editor'), {
    mode: 'text/x-csrc',
    lineNumbers: true,
    theme: 'eclipse',
    viewportMargin: Infinity
  });
  editor.on('change', function(e, obj) {
    $timeout(function() {
      $scope.documentChanged = true;
    });
  });
  saving = false;
  editor.on('beforeChange', function(e, obj) {
    if (saving) {
      obj.cancel();
    }
  });
  $scope.reload_ws = function() {
    return AppCatalogProvider.catalog.then(function(app_catalog) {
      var projects_resource, ref, ref1;
      projects_resource = (ref = app_catalog['Programs']) != null ? (ref1 = ref.web_api) != null ? ref1.projects : void 0 : void 0;
      if (projects_resource != null) {
        $http.get(projects_resource.uri + '/' + $scope.active_user.name).success(function(data, status, headers, config) {
          var project, selected;
          $scope.ws = data;
          $scope.ws.projects = ($scope.ws.projects || []).filter(function(p) { return p.parameters.user === $scope.active_user.name; }); 
          if ($location.search().project != null) {
            selected = (function() {
              var i, len, ref2, results;
              ref2 = $scope.ws.projects;
              results = [];
              for (i = 0, len = ref2.length; i < len; i++) {
                project = ref2[i];
                if (project.name === $location.search().project) {
                  results.push(project);
                }
              }
              return results;
            })();
            if (selected[0]) {
              $scope.select_project(selected[0]);
            } else {
              $location.search('project', null);
            }
            
          }
        });
        $http.get(projects_resource.uri + '/users').success(function(data, status, headers, config) {
          $scope.users = data.map(function(user, i) { return {id: i, name: user}; });
        });
      }
    });
  };
  $scope.reload_ws();
  $scope.delete_project = function(project) {
    return ButtonsOnlyModalFactory.open('Delete Project', 'Are you sure you want to permanently delete this project?', ['Yes', 'No']).then(function(button) {
      if (button === 'Yes') {
        $scope.close_project();
        return $http["delete"](project.links.self.href).success(function(data, status, headers, config) {
          return $scope.reload_ws();
        });
      }
    });
  };
  $scope.close_project = function() {
    $scope.close_file();
    $scope.project_resource = null;
    $location.search('project', null);
    return $scope.selected_project = null;
  };
  $scope.select_project = function(project) {
    $scope.selected_project = project;
    if ($location.search().project !== project.name) {
      $location.search('project', project.name);
    }
    return $http.get(project.links.self.href).success(function(data, status, headers, config) {
      var file, selected, selected_file, selected_file_cat;
      $scope.project_resource = data;
      selected_file = null;
      selected_file_cat = null;
      if ($location.search().file != null) {
        selected = [];
        if ($location.search().cat === 'include' && ($scope.project_resource.include_files != null)) {
          selected = (function() {
            var i, len, ref, results;
            ref = $scope.project_resource.include_files;
            results = [];
            for (i = 0, len = ref.length; i < len; i++) {
              file = ref[i];
              if (file.name === $location.search().file) {
                results.push(file);
              }
            }
            return results;
          })();
        } else if ($location.search().cat === 'src' && ($scope.project_resource.source_files != null)) {
          selected = (function() {
            var i, len, ref, results;
            ref = $scope.project_resource.source_files;
            results = [];
            for (i = 0, len = ref.length; i < len; i++) {
              file = ref[i];
              if (file.name === $location.search().file) {
                results.push(file);
              }
            }
            return results;
          })();
        } else if ($location.search().cat === 'data' && ($scope.project_resource.data_files != null)) {
          selected = (function() {
            var i, len, ref, results;
            ref = $scope.project_resource.data_files;
            results = [];
            for (i = 0, len = ref.length; i < len; i++) {
              file = ref[i];
              if (file.name === $location.search().file) {
                results.push(file);
              }
            }
            return results;
          })();
        }
        selected_file = selected[0];
        selected_file_cat = $location.search().cat;
      }
      if (!selected_file && $scope.project_resource.source_files) {
        selected_file = $scope.project_resource.source_files[0];
        selected_file_cat = 'src';
      }
      if (selected_file) {
        return $scope.select_file(selected_file, selected_file_cat);
      } else {
        return $scope.close_file();
      }
    });
  };
  $scope.select_file = function(file, file_type) {
    $scope.selected_file = file;
    $scope.compiler_output = '';
    $location.search('file', file.name);
    $location.search('cat', file_type);
    $http.get($scope.selected_file.links.self.href).success(function(data, status, headers, config) {
      $scope.display_file_menu = false;
      $scope.displayed_file = data;
      $timeout(function() {
        editor.setValue(new Buffer(data.content, 'base64').toString('ascii'));
        editor.refresh();
        return $timeout(function() {
          return $scope.documentChanged = false;
        });
      });
    });
  };
  $scope.close_file = function() {
    $scope.compiler_output = '';
    $scope.display_file_menu = false;
    $scope.displayed_file = null;
    $scope.selected_file = null;
    editor.setValue('');
    $scope.documentChanged = false;
    $location.search('file', null);
    return $location.search('cat', null);
  };
  $scope.delete_file = function(file) {
    return ButtonsOnlyModalFactory.open('Delete File', 'Are you sure you want to permanently delete this file?', ['Yes', 'No']).then(function(button) {
      if (button === 'Yes') {
        $http["delete"](file.links.self.href);
        $scope.close_file();
        $scope.select_project($scope.selected_project);
      }
    });
  };
  save_file = function() {
    var content;
    if ($scope.displayed_file != null) {
      content = editor.getValue();
      content = new Buffer(content).toString('base64');
      return $http.put($scope.displayed_file.links.self.href, {
        content: content,
        encoding: 'ascii'
      });
    }
  };
  $scope.save = function() {
    if ($scope.displayed_file != null) {
      saving = true;
      save_file().success(function(data, status, headers, config) {
        saving = false;
        $scope.documentChanged = false;
      }).error(function(data, status, headers, config) {
        saving = false;
      });
    }
  };
  on_window_beforeunload = function() {
    if ($scope.documentChanged) {
      return 'You have unsaved changes. Are you sure you want to leave this page and discard your changes?';
    } else {

    }
  };
  window.addEventListener('beforeunload', on_window_beforeunload);
  onRouteChangeOff = $rootScope.$on('$locationChangeStart', function(event, newUrl) {
    // workaround to detect in-app url updates
    if (newUrl.indexOf('/#/apps/kiss') !== -1) {
      return;
    }
    // remove query string
    if (newUrl.indexOf('?') !== -1) {
      newUrl = newUrl.substring(0, newUrl.indexOf('?'));
    }
    // remove host:port
    newUrl = newUrl.substring($location.absUrl().length - ($location.url().length));
    if ($scope.documentChanged) {
      ButtonsOnlyModalFactory.open('You have unsaved changes', 'You have unsaved changes! Would you like to save them before leaving this page?', ['Save', 'Discard', 'Cancel']).then(function(button) {
        if (button === 'Save') {
          $scope.save();
          $location.path(newUrl.substring($location.absUrl().length - ($location.url().length)));
          onRouteChangeOff();
          window.removeEventListener('beforeunload', on_window_beforeunload);
        } else if (button === 'Discard') {
          $location.path(newUrl);
          onRouteChangeOff();
          window.removeEventListener('beforeunload', on_window_beforeunload);
        }
      });
      event.preventDefault();
    } else {
      onRouteChangeOff();
      window.removeEventListener('beforeunload', on_window_beforeunload);
    }
  });
  $scope.refresh = function() {};
  $scope.undo = function() {
    editor.undo();
  };
  $scope.redo = function() {
    editor.redo();
  };
  $scope.download_project = function(project) {
    return DownloadProjectModalFactory.open(project);
  };
  $scope.show_add_include_file_modal = function() {
    return FilenameModalFactory.open('Create New Include File', 'Choose a filename:', 'Filename', ['.h'], 'Create').then(function(data) {
      if (($scope.ws != null) && ($scope.project_resource != null)) {
        return $http.post($scope.project_resource.links.include_directory.href, {
          name: data.filename + data.extension,
          type: 'file'
        }).success(function(data, status, headers, config) {
          return $scope.select_project($scope.selected_project);
        });
      }
    });
  };
  $scope.show_add_source_file_modal = function() {
    var language_array;
    language_array = ['.c'];
    if ($scope.project_resource.parameters.language === 'Python') {
      language_array = ['.py'];
    }
    return FilenameModalFactory.open('Create New Source File', 'Choose a filename:', 'Filename', language_array, 'Create').then(function(data) {
      if (($scope.ws != null) && ($scope.project_resource != null)) {
        return $http.post($scope.project_resource.links.src_directory.href, {
          name: data.filename + data.extension,
          type: 'file'
        }).success(function(data, status, headers, config) {
          return $scope.select_project($scope.selected_project);
        });
      }
    });
  };
  $scope.show_add_data_file_modal = function() {
    return FilenameModalFactory.open('Create User Data File', 'Choose a filename:', 'Filename', null, 'Create').then(function(data) {
      if (($scope.ws != null) && ($scope.project_resource != null)) {
        return $http.post($scope.project_resource.links.data_directory.href, {
          name: data.filename,
          type: 'file'
        }).success(function(data, status, headers, config) {
          return $scope.select_project($scope.selected_project);
        });
      }
    });
  };
  $scope.close_file_menu = function() {
    return $scope.display_file_menu = false;
  };
  $scope.open_file_menu = function() {
    return $scope.display_file_menu = true;
  };
  $scope.show_add_project_modal = function() {
    $('#new-project').modal('show');
  };
  $scope.hide_add_project_modal = function() {
    return $('#new-project').modal('hide');
  };
  $scope.add_project = function() {
    $('#new-project').modal('hide');
    AppCatalogProvider.catalog.then(function(app_catalog) {
      var projects_resource, ref, ref1;
      projects_resource = (ref = app_catalog['Programs']) != null ? (ref1 = ref.web_api) != null ? ref1.projects : void 0 : void 0;
      if (projects_resource != null) {
        $http.post(projects_resource.uri, {
          name: $("#projectName").val(),
          user: $scope.active_user.name,
          language: $("#programmingLanguage").val(),
          src_file_name: $("#sourceFileName").val()
        }).success(function(data, status, headers, config) {
          $scope.reload_ws();
        });
      }
    });
  };
  $scope.defaultProgrammingLanguage = 'C';
  $scope.change_filename = function() {
    if ($("#programmingLanguage").val() === "Python") {
      $("#sourceFileName").val("main.py");
    } else {
      $("#sourceFileName").val("main.c");
    }
  };
  $scope.indent = function() {
    editor.execCommand('selectAll');
    editor.execCommand('indentAuto');
    editor.setCursor(editor.lineCount(), 0);
  };

  $scope.users = [
    {id: 0, name: 'Default User'}
  ];
  $scope.active_user = $scope.users[0];

  $scope.show_new_user_modal = function() {
    $('#new-user').modal('show');
  };
  $scope.hide_new_user_modal = function() {
    return $('#new-user').modal('hide');
  };

  $scope.add_user = function() {
    $scope.show_new_user_modal();
  };

  $scope.new_user = function() {
    $('#new-user').modal('hide');

    var username = $("#userName").val();
    AppCatalogProvider.catalog.then(function(app_catalog) {
      var projects_resource, ref, ref1;
      projects_resource = (ref = app_catalog['Programs']) != null ? (ref1 = ref.web_api) != null ? ref1.projects : void 0 : void 0;
      if (!projects_resource) return;
      $http.put(projects_resource.uri + '/users/' + username).success(function(data, status) {
        if(status !== 204) throw new Error('Failed to create new user');
        $scope.reload_ws().then(function () {
          $scope.active_user = $scope.users.filter(function(user) {
            return user.name === username;
          })[0] || $scope.active_user;
        });
      });
    });
  };

  $scope.remove_active_user = function() {
    var username = $scope.active_user.name;
    AppCatalogProvider.catalog.then(function(app_catalog) {
      var projects_resource, ref, ref1;
      projects_resource = (ref = app_catalog['Programs']) != null ? (ref1 = ref.web_api) != null ? ref1.projects : void 0 : void 0;
      if (!projects_resource) return;
      $http.delete(projects_resource.uri + '/users/' + username).success(function(data, status) {
        if(status !== 204) throw new Error('Failed to create new user');
        $scope.reload_ws().then(function () {
          $scope.active_user = $scope.users[0];
        });
      });
    });
  }

  $scope.$watch('active_user', function(newValue, oldValue) {
    $scope.reload_ws();
  });

  compile = function(project_name) {
    $scope.is_compiling = true;
    return $http.post('/api/compile', {
      name: project_name,
      user: $scope.active_user.name
    }).success(function(data, status, headers, config) {
      var ref;
      $scope.is_compiling = false;
      if (data.result.error != null) {
        $scope.compilation_state = 'Compilation Failed';
        if (((ref = data.result.error) != null ? ref.message : void 0) != null) {
          return $scope.compiler_output = 'Compilation Failed\n\n' + data.result.error.message;
        } else {
          return $scope.compiler_output = 'Compilation Failed\n\n' + data.result.stderr + data.result.stdout;
        }
      } else if (data.result.stderr) {
        $scope.compilation_state = 'Compilation Succeeded with Warnings';
        return $scope.compiler_output = 'Compilation Succeeded with Warnings\n\n' + data.result.stderr + data.result.stdout;
      } else {
        $scope.compilation_state = 'Compilation succeeded';
        return $scope.compiler_output = 'Compilation succeeded\n\n' + data.result.stdout;
      }
    });
  };
  return $scope.compile = function() {
    $scope.compiler_output = null;
    if ($scope.selected_project != null) {
      if ($scope.displayed_file != null) {
        return save_file().success(function(data, status, headers, config) {
          $scope.documentChanged = false;
          return compile($scope.selected_project.name);
        });
      } else {
        return compile($scope.selected_project.name);
      }
    }
  };
};

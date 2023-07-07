var code_mirror;
var dark_mode;
require('codemirror/mode/clike/clike'); // allows c/c++ highlighting
require('codemirror/mode/python/python'); // allows real python highlighting

code_mirror = require('codemirror/lib/codemirror');

Io = require('socket.io-client');

exports.name = 'KissViewController';

exports.inject = function (app) {
    app.controller(exports.name, [
        '$scope',
        '$rootScope',
        '$location',
        '$http',
        '$timeout',
        'AppCatalogProvider',
        'ProgramService',
        'ButtonsOnlyModalFactory',
        'DownloadProjectModalFactory',
        'FilenameModalFactory',
        exports.controller
    ]);
};

exports.controller = function ($scope, $rootScope, $location, $http, $timeout, AppCatalogProvider, ProgramService, ButtonsOnlyModalFactory, DownloadProjectModalFactory, FilenameModalFactory) {
    var compile,
        editor,
        onRouteChangeOff,
        on_window_beforeunload,
        save_file,
        saving,
        mode;
    mode = "text/x-csrc" // c by default
    $scope.is_compiling = false;
    $scope.documentChanged = false;
    $scope.ProgramService = ProgramService;

    const DarkModeToggleButton = document.getElementById('darkModeBtn');

    DarkModeToggleButton.addEventListener("click", () => { // $scope.reload_ws();
        if ($scope.runner == true) {
            var runnerOutput = document.querySelectorAll('.cm-s-material-palenight')[0];
            if (localStorage.getItem('darkMode') == 'enabled') {
                runnerOutput.classList.remove('runnerDark');
            } else {
                runnerOutput.classList.add('runnerDark');
            }

            if (document.body.classList.contains('dark')) { // when the body has the class 'dark' currently
                localStorage.setItem('darkMode', 'enabled'); // store this data if dark mode is on
            } else {
                localStorage.setItem('darkMode', 'disabled'); // store this data if dark mode is off
            }

        }

        $scope.reload_ws();
    });
    $scope.$on('$routeUpdate', function (next, current) {
        var ref,
            ref1;
        if ((((ref = $scope.displayed_file) != null ? ref.name : void 0) !== $location.search().file) || (((ref1 = $scope.selected_project) != null ? ref1.name : void 0) !== $location.search().project)) {
            $scope.reload_ws();
            let cur_file = $location.search().file;

            mode = "text/x-";
            if (cur_file == undefined) { // default is just c formatting
                mode += "csrc";
            } else if (cur_file.includes(".cpp") || cur_file.includes(".hpp")) {
                mode += "c++src";
            } else if (cur_file.includes(".c") || cur_file.includes(".h")) {
                mode += "csrc";
            } else if (cur_file.includes(".py")) {
                mode += "python"
            } else {
                mode += "csrc" // by default, use c highlighting
            }
            if (editor != null) {
                editor.setOption("mode", mode);
            }
        }
    });
    editor = code_mirror.fromTextArea(document.getElementById('editor'), {
        mode: mode,
        lineNumbers: true,
        indentUnit: 4,
        smartIndent: true,
        indentWithTabs: false,
        theme: 'kiss-default',
        viewportMargin: Infinity
    });

    editor.on('change', function (e, obj) {
        $timeout(function () {

            $scope.documentChanged = true;
            var saveButton = document.getElementById('saveButton');

            if (localStorage.getItem('darkMode') == 'enabled') {
                if ($scope.documentChanged) {
                    saveButton.classList.add('editorSaveChanged-Dark');
                } else {
                    saveButton.classList.remove('editorSaveChanged-Dark');
                }
            }

        });
    });
    saving = false;
    editor.on('beforeChange', function (e, obj) {
        if (saving) {
            obj.cancel();
        }
    });

    sort_users = function (users) {
        users.sort(function (a, b) {
            var nameA = a.name.toUpperCase();
            var nameB = b.name.toUpperCase();

            if (nameA === "DEFAULT USER") {
                return -1;
            }

            if (nameB === "DEFAULT USER") {
                return 1;
            }

            if (nameA < nameB) {
                return -1;
            }
            if (nameA > nameB) {
                return 1;
            }

            return 0;
        });

        return users;
    }

    $scope.reload_ws = function () {

        return AppCatalogProvider.catalog.then(function (app_catalog) {
            var projects_resource,
                ref,
                ref1;
            projects_resource = (ref = app_catalog['Programs']) != null ? (ref1 = ref.web_api) != null ? ref1.projects : void 0 : void 0;
            if (projects_resource != null) {
                $http.get(projects_resource.uri + '/' + $scope.active_user.name).success(function (data, status, headers, config) {
                    var project,
                        selected;
                    $scope.ws = data;
                    $scope.ws.projects = ($scope.ws.projects || []).filter(function (p) {
                        return p.parameters.user === $scope.active_user.name;
                    }).sort();
                    if ($location.search().project != null) {
                        selected = (function () {
                            var i,
                                len,
                                ref2,
                                results;
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
                $http.get(projects_resource.uri + '/users').success(function (data, status, headers, config) {
                    $scope.users = Object.keys(data).map(function (user, i) {
                        return {id: i, name: user, data: data[user]};
                    });
                    $scope.users = sort_users($scope.users);
                });
            }
        });
    };
    $scope.reload_ws();
    $scope.delete_project = function (project) {
        return ButtonsOnlyModalFactory.open('Delete Project', 'Are you sure you want to permanently delete this project?', ['Yes', 'No']).then(function (button) {
            if (button === 'Yes') {
                $scope.close_project();
                return $http["delete"](project.links.self.href).success(function (data, status, headers, config) {
                    return $scope.reload_ws();
                });
            }
        });
    };
    $scope.close_project = function () {
        $scope.close_file();
        $scope.project_resource = null;
        $location.search('project', null);
        return $scope.selected_project = null;
    };
    $scope.select_project = function (project) {
        $scope.selected_project = project;
        if ($location.search().project !== project.name) {
            $location.search('project', project.name);

        }


        return $http.get(project.links.self.href).success(function (data, status, headers, config) {
            var file,
                selected,
                selected_file,
                selected_file_cat;
            $scope.project_resource = data;
            selected_file = null;
            selected_file_cat = null;


            if ($location.search().file != null) {
                selected = [];
                if ($location.search().cat === 'include' && ($scope.project_resource.include_files != null)) {
                    selected = (function () {
                        var i,
                            len,
                            ref,
                            results;
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
                    selected = (function () {
                        var i,
                            len,
                            ref,
                            results;
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
                    selected = (function () {
                        var i,
                            len,
                            ref,
                            results;
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
            if (! selected_file && $scope.project_resource.source_files) {
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
    var overall_selected_file;
    $scope.select_file = function (file, file_type) {

        $scope.selected_file = file;
        $scope.compiler_output = '';
        $location.search('file', file.name);
        $location.search('cat', file_type);


        $http.get($scope.selected_file.links.self.href).success(function (data, status, headers, config) {
            $scope.display_file_menu = false;
            $scope.displayed_file = data;
            $timeout(function () {
                editor.setValue(new Buffer(data.content, 'base64').toString('ascii'));
                editor.refresh();
                var saveButton = document.getElementById('saveButton');
                var buttons = document.getElementsByTagName('button');
                
                if (localStorage.getItem('darkMode') == 'enabled') {
                    saveButton.classList.add('editorSave-Dark');
                    for (var i = 0; i < buttons.length; i++) {
                      buttons[i].classList.add('panelButton-dark');
                    }
                } else {
                    saveButton.classList.remove('editorSave-Dark');
                    for (var i = 0; i < buttons.length; i++) {
                      buttons[i].classList.remove('panelButton-dark');
                    }
                }
                return $timeout(function () { // This block changes Project Explorer table theme colors
                    var project_explorer = document.querySelectorAll('.panel.panel-primary.panel-stretch:not(panel-heading)')[4];
                    var project_container_table = project_explorer.getElementsByTagName("tbody")[0]; // Project Explorer Table
                    var project_table_row = project_container_table.getElementsByTagName("tr"); // Table row array object
                    var table_row = Array.from(project_table_row);
                    table_row.forEach(item => table_change(item)); // each row in table

                    return $scope.documentChanged = false;

                });
            });
        });
    };
    $scope.close_file = function () {
        $scope.compiler_output = '';
        $scope.display_file_menu = false;
        $scope.displayed_file = null;
        $scope.selected_file = null;
        editor.setValue('');
        $scope.documentChanged = false;
        $location.search('file', null);
        return $location.search('cat', null);
    };
    $scope.delete_file = function (file) {
        const project_resource = $scope.project_resource;
        const total_files = project_resource.include_files.length + project_resource.source_files.length + project_resource.data_files.length;
        if (total_files === 1) {
            return ButtonsOnlyModalFactory.open('Delete Project', 'This is the last file in the project. Do you want to delete the project?', ['Yes', 'No']).then(function (button) {
                if (button !== 'Yes') {
                    // We have to delete project if it is the last file in simple mode
                    // because simple mode doesn't allow another means to upload
                    if ($scope.active_user.data.mode === "Simple") 
                        return;
                    


                    return ButtonsOnlyModalFactory.open('Delete File', 'Are you sure you want to permanently delete this file (' + file.name + ') ?', ['Yes', 'No']).then(function (button) {
                        if (button !== 'Yes') 
                            return;
                        


                        $http["delete"](file.links.self.href);
                        $scope.close_file();
                        $scope.select_project($scope.selected_project);
                    });
                }
                const project = $scope.selected_project;
                $scope.close_project();
                return $http["delete"](project.links.self.href).success(function (data, status, headers, config) {
                    return $scope.reload_ws();
                });
            });
        }

        return ButtonsOnlyModalFactory.open('Delete File', 'Are you sure you want to permanently delete this file (' + file.name + ') ?', ['Yes', 'No']).then(function (button) {
            if (button !== 'Yes') 
                return;
            


            $http["delete"](file.links.self.href);
            $scope.close_file();
            $scope.select_project($scope.selected_project);
        });
    };
    save_file = function () {
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
    $scope.save = function () {
        if ($scope.displayed_file != null) {
            saving = true;
            save_file().success(function (data, status, headers, config) {
                var saveButton = document.getElementById('saveButton');
                saveButton.classList.remove('editorSaveChanged-Dark');
                saving = false;
                $scope.documentChanged = false;
            }).error(function (data, status, headers, config) {
                saving = false;
            });
        }
    };
    on_window_beforeunload = function () {
        if ($scope.documentChanged) {
            return 'You have unsaved changes. Are you sure you want to leave this page and discard your changes?';
        } else {}
    };
    window.addEventListener('beforeunload', on_window_beforeunload);
    onRouteChangeOff = $rootScope.$on('$locationChangeStart', function (event, newUrl) { // workaround to detect in-app url updates
        if (newUrl.indexOf('/#/apps/kiss') !== -1) {
            return;
        }
        // remove query string
        if (newUrl.indexOf('?') !== -1) {
            newUrl = newUrl.substring(0, newUrl.indexOf('?'));
        }
        // remove host:port
        newUrl = newUrl.substring($location.absUrl().length -($location.url().length));
        if ($scope.documentChanged) {
            ButtonsOnlyModalFactory.open('You have unsaved changes', 'You have unsaved changes! Would you like to save them before leaving this page?', ['Save', 'Discard', 'Cancel']).then(function (button) {
                if (button === 'Save') {
                    $scope.save();
                    $location.path(newUrl.substring($location.absUrl().length -($location.url().length)));
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
    $scope.refresh = function () {};
    $scope.undo = function () {
        editor.undo();
    };
    $scope.redo = function () {
        editor.redo();
    };
    $scope.download_project = function (project) {
        return DownloadProjectModalFactory.open(project);
    };
    $scope.show_add_include_file_modal = function () {
        return FilenameModalFactory.open('Create New Include File', 'Filename', ['.h'], 'Create').then(function (mData) {
            if ($scope.ws == null || $scope.project_resource == null) 
                return;
            


            var file = {
                name: mData.filename ? (mData.filename + mData.extension) : mData.upload.name,
                type: 'file',
                content: mData.upload ? window.btoa(mData.upload.content) : ''
            };

            return $http.post($scope.project_resource.links.include_directory.href, file).success(function (data, status, headers, config) {
                $scope.select_file(file, "include");
                return $scope.select_project($scope.selected_project);
            });
        });
    };

    $scope.show_add_source_file_modal = function () {
        var language_array = ['.c'];
        if ($scope.project_resource.parameters.language === 'Python') {
            language_array = ['.py'];
        }
        if ($scope.project_resource.parameters.language === 'C++') {
            language_array = ['.cpp'];
        }

        return FilenameModalFactory.open('Create New Source File', 'Filename', language_array, 'Create').then(function (mData) {
            if ($scope.ws == null || $scope.project_resource == null) 
                return;
            


            var file = {
                name: mData.filename ? (mData.filename + mData.extension) : mData.upload.name,
                type: 'file',
                content: mData.upload ? window.btoa(mData.upload.content) : ''
            };

            return $http.post($scope.project_resource.links.src_directory.href, file).success(function (data, status, headers, config) {
                $scope.select_file(file, "src");
                return $scope.select_project($scope.selected_project);
            });
        });
    };

    $scope.show_add_data_file_modal = function () {
        return FilenameModalFactory.open('Create User Data File', 'Filename', null, 'Create').then(function (mData) {
            if ($scope.ws == null || $scope.project_resource == null) 
                return;
            


            var file = {
                name: mData.filename ? (mData.filename) : mData.upload.name,
                type: 'file',
                content: mData.upload ? window.btoa(mData.upload.content) : ''
            };

            return $http.post($scope.project_resource.links.data_directory.href, file).success(function (data, status, headers, config) {
                $scope.select_file(file, "data");
                return $scope.select_project($scope.selected_project);
            });
        });
    };

    $scope.close_file_menu = function () {
        return $scope.display_file_menu = false;
    };
    $scope.open_file_menu = function () {
        return $scope.display_file_menu = true;
    };

    table_change = function (item) { // item is 1 table row array object
        var i;
        var td = item.getElementsByTagName("td");
        var th = item.getElementsByTagName("th");

        var table_data = Array.from(td);
        var table_row_header = Array.from(th);

        Array.from(td).forEach(element => element.style.backgroundColor = '#05284e');
        Array.from(td).forEach(element => element.style.color = '#ffffff');
        Array.from(th).forEach(element => element.style.backgroundColor = '#05284e');
        Array.from(th).forEach(element => element.style.color = '#ffffff');


        if (localStorage.getItem('darkMode') == 'enabled') { // if currently in dark mode --> change to dark aspects

            for (i = 0; i < table_data.length; i++) { // changes td tag

                if (item.classList.contains("info")) { // currently selected file
                    table_data[i].style.backgroundColor = '#42a5d7';
                    table_data[i].style.color = '#ffffff';
                }

            }
          
            for (i = 0; i < table_row_header.length; i++) { // changes th tag
                if (item.classList.contains("info")) {
                    table_row_header[i].style.backgroundColor = '#42a5d7';
                    table_row_header[i].style.color = '#ffffff';
                } else {
                    table_row_header[i].style.backgroundColor = '#05284e';
                    table_row_header[i].style.color = '#ffffff';
                }
            }
    

        } else if (localStorage.getItem('darkMode') == 'disabled') { // if currently in light mode --> change to light aspects

            for (i = 0; i < table_data.length; i++) { // change td tag
                if (item.classList.contains("info")) {

                    table_data[i].style.backgroundColor = '#d9edf7';
                    table_data[i].style.color = '#291c10';

                } else {
                    table_data[i].style.backgroundColor = '#f5f5f5';
                    table_data[i].style.color = '#291c10';
                }
            }
            for (i = 0; i < table_row_header.length; i++) { // change th tag
                if (item.classList.contains("info")) {

                    table_row_header[i].style.backgroundColor = '#d9edf7';
                    table_row_header[i].style.color = '#291c10';

                } else {
                    table_row_header[i].style.backgroundColor = '#f5f5f5';
                    table_row_header[i].style.color = '#291c10';
                }
            }

        }

    };


    $scope.show_add_project_modal = function () {
        $scope.change_filename();
        $('#projectName').val(undefined);
        $('#new-project').modal('show');
    };
    $scope.hide_add_project_modal = function () {
        $('#new-project').modal('hide');
    };
    $scope.add_project = function () {
        $('#new-project').modal('hide');
        AppCatalogProvider.catalog.then(function (app_catalog) {
            var projects_resource,
                ref,
                ref1;
            projects_resource = (ref = app_catalog['Programs']) != null ? (ref1 = ref.web_api) != null ? ref1.projects : void 0 : void 0;
            if (projects_resource != null) {
                $http.post(projects_resource.uri, {
                    name: $("#projectName").val(),
                    user: $scope.active_user.name,
                    language: $("#programmingLanguage").val(),
                    src_file_name: $("#sourceFileName").val()
                }).success(function (data, status, headers, config) {
                    $location.search('project', $("#projectName").val());
                    $scope.reload_ws();
                });
            }
        });
    };
    $scope.defaultProgrammingLanguage = 'C';
    $scope.change_filename = function () {
        if ($("#programmingLanguage").val() === "Python") {
            $("#sourceFileName").val("main.py");
        } else if ($("#programmingLanguage").val() === "C") {
            $("#sourceFileName").val("main.c");
        } else { // it's c++
            $("#sourceFileName").val("main.cpp");
        }
    };
    $scope.indent = function () {
        editor.execCommand('selectAll');
        editor.execCommand('indentAuto');
        editor.setCursor(editor.lineCount(), 0);
    };

    $scope.users = [{
            id: 0,
            name: 'Default User'
        }];
    $scope.active_user = $scope.users[0];

    $scope.show_new_user_modal = function () {
        $('#new-user').modal('show');
    };
    $scope.hide_new_user_modal = function () {
        $('#new-user').modal('hide');
    };

    $scope.add_user = function () {
        $scope.show_new_user_modal();
    };

    $scope.new_user = function () {
        $('#new-user').modal('hide');

        var username = $("#userName").val();
        AppCatalogProvider.catalog.then(function (app_catalog) {
            var projects_resource,
                ref,
                ref1;
            projects_resource = (ref = app_catalog['Programs']) != null ? (ref1 = ref.web_api) != null ? ref1.projects : void 0 : void 0;
            if (! projects_resource) 
                return;
            


            $http.put(projects_resource.uri + '/users/' + username).success(function (data, status) {
                if (status !== 204) 
                    throw new Error('Failed to create new user');
                


                // reload users
                $http.get(projects_resource.uri + '/users').success(function (data, status, headers, config) {
                    $scope.users = Object.keys(data).map(function (user, i) {
                        return {id: i, name: user, data: data[user]};
                    });
                    $scope.active_user = $scope.users.filter(function (user) {
                        return user.name === username;
                    })[0] || $scope.active_user;
                });
            });
        });

        $scope.reload_ws();
    }


    $scope.remove_active_user = function () {
        var username = $scope.active_user.name;
        return ButtonsOnlyModalFactory.open('Remove User', 'Are you sure you want to permanently remove ' + username + ' and all of their projects?', ['Yes', 'No']).then(function (button) {
            if (button !== 'Yes') 
                return;
            


            AppCatalogProvider.catalog.then(function (app_catalog) {
                var projects_resource,
                    ref,
                    ref1;
                projects_resource = (ref = app_catalog['Programs']) != null ? (ref1 = ref.web_api) != null ? ref1.projects : void 0 : void 0;
                if (! projects_resource) 
                    return;
                


                $http.delete(projects_resource.uri + '/users/' + username).success(function (data, status) {
                    if (status !== 204) 
                        throw new Error('Failed to create new user');
                    


                    $scope.reload_ws().then(function () {
                        $scope.active_user = $scope.users[0];
                    });
                });
            });
        });

    }

    $scope.$watch('active_user', function (newValue, oldValue) {
        $scope.close_project();
        $scope.close_file();
        $scope.reload_ws();
    });

    compile = function (project_name) { // $scope.stop();
        $scope.is_compiling = true;
        return $http.post('/api/compile', {
            name: project_name,
            user: $scope.active_user.name
        }).success(function (data, status, headers, config) {
            var ref;
            $scope.is_compiling = false;
            var compilerPanel = document.querySelectorAll('.compiler');
            compilerPanel[0].classList.remove('panelHeading-dark');
            if (data.result.error != null) {
                $scope.compilation_state = 'Compilation Failed';
                if (localStorage.getItem('darkMode') == 'enabled') {
                    compilerPanel[0].classList.add('panelDark-Failed');
                    compilerPanel[0].classList.remove('panelDark-Warning');
                }

                if (((ref = data.result.error) != null ? ref.message : void 0) != null) {
                    return $scope.compiler_output = 'Compilation Failed\n\n' + data.result.error.message;
                } else {
                    return $scope.compiler_output = 'Compilation Failed\n\n' + data.result.stderr + data.result.stdout;
                }
            } else if (data.result.stderr) {
                $scope.compilation_state = 'Compilation Succeeded with Warnings';
                if (localStorage.getItem('darkMode') == 'enabled') {
                    compilerPanel[0].classList.add('panelDark-Warning');
                    compilerPanel[0].classList.remove('panelDark-Failed');
                    compilerPanel[0].classList.remove('panelDark-Success');
                }
                return $scope.compiler_output = 'Compilation Succeeded with Warnings\n\n' + data.result.stderr + data.result.stdout;
            } else {
                $scope.compilation_state = 'Compilation succeeded';
                if (localStorage.getItem('darkMode') == 'enabled') {
                    compilerPanel[0].classList.add('panelDark-Success');
                    compilerPanel[0].classList.remove('panelDark-Failed');
                    compilerPanel[0].classList.remove('panelDark-Warning');

                }
                return $scope.compiler_output = 'Compilation succeeded\n\n' + data.result.stdout;
            }
        });
    };
    $scope.compile = function () {
        $scope.compiler_output = null;
        if ($scope.selected_project != null) {
            if ($scope.displayed_file != null) {
                return save_file().success(function (data, status, headers, config) {
                    $scope.documentChanged = false;
                    return compile($scope.selected_project.name);
                });
            } else {
                return compile($scope.selected_project.name);
            }
        }
    };

    AppCatalogProvider.catalog.then(function (app_catalog) {
        var events_namespace,
            ref,
            ref1,
            ref2,
            ref3;
        events = (ref = app_catalog['Runner']) != null ? (ref1 = ref.event_groups) != null ? ref1.runner_events.events : void 0 : void 0;
        events_namespace = (ref2 = app_catalog['Runner']) != null ? (ref3 = ref2.event_groups) != null ? ref3.runner_events.namespace : void 0 : void 0;
        if (events != null) {
            socket = Io(':8888' + events_namespace);
            return socket.on(events.stdout.id, function (msg) {
                return $scope.$broadcast('runner-program-output', msg);
            });
        }
    });
    $scope.$on('runner-program-input', function (event, text) {
        if ((socket != null) && (events != null)) {
            return socket.emit(events.stdin.id, text);
        }
    });
    $scope.run = function () {
        if ($scope.selected_project != null) {
            if ($scope.is_compiling != true) {
                $scope.img_src = null;
                $scope.$broadcast("runner-reset-terminal");
                $scope.runner = true;
                $scope.compiler_output = '';
                if ($scope.runner == true) {
                    var runnerOutput = document.querySelectorAll('.cm-s-material-palenight')[0];
                    if (localStorage.getItem('darkMode') == 'enabled') {
                        if (! runnerOutput.classList.contains('runnerDark')) {}runnerOutput.classList.add('runnerDark');
                    } else {
                        if (runnerOutput.classList.contains('runnerDark')) {}runnerOutput.classList.remove('runnerDark');

                    }
                }
                return ProgramService.run($scope.selected_project.name, $scope.active_user.name);
            }
        }
    };
    $scope.toggle_run = function () {
        if (ProgramService.running) 
            return $scope.stop();
        


        return $scope.run();
    }
    $scope.hide_runner = function () {
        $scope.runner = false;
    }
    return $scope.stop = function () {
        $scope.is_compiling = false;
        if (! ProgramService.running) 
            return;
        


        return ProgramService.stop();
    };
};

const {controller} = require('../../../apps/kiss/resources/kiss-view-controller.js');

var angular,
    app,
    app_name,
    app_obj,
    bind = function (fn, me) {
        return function () {
            return fn.apply(me, arguments);
        };
    };

var dark_mode;
angular = require('angular');

require('angular-route');

app = angular.module('harrogateIndexApp', ['ngRoute', 'ui.bootstrap']);

require('./app-catalog-provider.js').inject(app);

require('./buttons-only-modal-factory-service.js').inject(app);

require('./download-project-modal-factory-service.js').inject(app);

require('./filename-modal-factory-service.js').inject(app);

require('./terminal-directive.js').inject(app);

require('./round-slider-directive.js').inject(app);

require('./fileread-directive.js').inject(app);

require('./user-manager-service.js').inject(app);

require('./workspace-manager-service.js').inject(app);

// inject the apps
for (app_name in app_catalog) {
    app_obj = app_catalog[app_name];
    if (app_obj.angular_ctrl != null) {
        require(app_name).inject(app);
    }
}


// from http://stackoverflow.com/questions/14512583/how-to-generate-url-encoded-anchor-links-with-angularjs
app.filter('escape', function () {
    return window.encodeURIComponent;
});

app.filter('capitalize', function () {
    return function (input) {
        if (input != null) {
            return input.charAt(0).toUpperCase() + input.substr(1);
        } else {
            return '';
        }
    };
});

app.service('authRequiredInterceptor', [
    '$q', '$location', function ($q, $location) {
        var AuthRequiredInterceptor;
        AuthRequiredInterceptor = (function () {
            function AuthRequiredInterceptor() {
                this.responseError = bind(this.responseError, this);
                this.last_intercepted_path = null;
            }

            AuthRequiredInterceptor.prototype.responseError = function (response) {
                if (response.status === 401) {
                    this.last_intercepted_path = $location.path();
                    $location.path('/apps/user');
                }
                return $q.reject(response);
            };

            return AuthRequiredInterceptor;

        })();
        return new AuthRequiredInterceptor;
    }
]);

var handle = -1;

app.controller('statusBarCtrl', [
    '$scope', '$http', 'UserManagerService', function ($scope, $http, UserManagerService) {
        $scope.connected = true;
        if (handle >= 0) 
            window.clearInterval(handle);
        


        handle = window.setInterval(function () {
            $http.get('/').then(function () {
                $scope.connected = true;
            }, function () {
                $scope.connected = false;
            });
        }, 10000);

    }
]);

app.controller('darkModeCtrl', [
    '$scope', '$http', 'UserManagerService', function ($scope, $http, UserManagerService) {
        const DarkModeToggleButton = document.getElementById('darkModeBtn');
        if (DarkModeToggleButton) {
            console.log("Yep");
        }


        DarkModeToggleButton.addEventListener("click", () => {
            //console.log("LocalStorage: " + localStorage.getItem('darkMode'));
            document.body.classList.toggle('dark'); // toggle the HTML body the class 'dark'
            if (document.body.classList.contains('dark')) { // when the body has the class 'dark' currently
                localStorage.setItem('darkMode', 'enabled'); // store this data if dark mode is on
            } else {
                localStorage.setItem('darkMode', 'disabled'); // store this data if dark mode is off
            } 
            console.log("LocalStorage: " + localStorage.getItem('darkMode'));
            toggle();

        });
        toggle();
        function toggle() {
            var viewContainer = document.getElementById('view-container');

            var navbar = viewContainer.getElementsByClassName('navbar')[0];
            var topBannerStrip = viewContainer.getElementsByClassName('container-fluid')[0];
            var viewContentContainer = document.getElementsByClassName('container-fluid ng-scope')[0];
            var contentContainer = viewContentContainer.getElementsByClassName('container')[0];
            var panel = document.getElementsByClassName('panel');
            var panelStretch = document.getElementsByClassName('panel-stretch');
            var button = document.getElementsByClassName('btn');
            var compilerPanel = document.querySelectorAll('.panel-success, .panel-danger, .panel-warning ')[0];
            var darkModeImage = DarkModeToggleButton.getElementsByTagName("i")[0];
            var darkModeText = DarkModeToggleButton.getElementsByTagName("small")[0];

            if (localStorage.getItem('darkMode') == 'enabled') { // dark mode settings

                viewContainer.classList.add("viewContainer-dark");
                topBannerStrip.classList.add("container-fluid-dark");
                navbar.classList.add("navbar-dark");

                for (var i = 0; i < panel.length; i++) {
                    panel[i].children[0].classList.add("panelHeading-dark");
                    panel[i].children[0].classList.remove('panel-heading');
                    panel[i].children[1].classList.add("panelBody-dark");
                }

                for (var i = 0; i < button.length; i++) {
                    button[i].classList.add('panelButton-dark');
                }

                darkModeImage.classList.remove("fa-moon-o");
                darkModeImage.classList.add("fa-sun-o");
                darkModeText.innerHTML = "Light Mode";

            } else { // light mode settings

                viewContainer.classList.remove("viewContainer-dark");
                topBannerStrip.classList.remove("container-fluid-dark");
                navbar.classList.remove("navbar-dark");

                for (var i = 0; i < panel.length; i++) {
                    panel[i].children[0].classList.remove("panelHeading-dark");
                    panel[i].children[0].classList.add('panel-heading');
                    panel[i].children[1].classList.remove("panelBody-dark");

                }
                for (var i = 0; i < button.length; i++) {
                    button[i].classList.remove('panelButton-dark');
                }
                darkModeImage.classList.remove("fa-sun-o");
                darkModeImage.classList.add("fa-moon-o");
                darkModeText.innerHTML = "Dark Mode";
            }
        }


    }

]);


app.config([
    // redirect by default to home (let's hope that an app called 'home' always exists...)
    '$routeProvider',
    '$httpProvider',
    function ($routeProvider, $httpProvider, $location) {
        $routeProvider.when('/', {redirectTo: '/apps/home'});

        // add the routes for the apps
        for (app_name in app_catalog) {
            app_obj = app_catalog[app_name];
            if (app_obj.angular_ctrl != null) {
                $routeProvider.when(app_obj.angularjs_route, {
                    templateUrl: app_obj.nodejs_route,
                    controller: require(app_name).controller,
                    reloadOnSearch: false
                });
            } else {
                $routeProvider.when(app_obj.angularjs_route, {templateUrl: app_obj.nodejs_route});
            }
        }
        // setup 401 interception
        $httpProvider.interceptors.push('authRequiredInterceptor');
    }
]);

app.directive('setFocus', function ($timeout, $parse) {
    return {
        restrict: "A",
        scope: {
            setFocus: '='
        },
        link: function ($scope, element, attrs) {
            $scope.$watch('setFocus', function (value) {
                if (value === true) {
                    $timeout(function () {
                        element[0].focus();
                    });
                }
            });
        }
    };
});

app.run();

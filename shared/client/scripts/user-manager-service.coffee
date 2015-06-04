exports.name = 'user_manager_service'

exports.inject = (app) ->
  app.service exports.name, [
    '$http'
    '$q'
    '$location'
    'authRequiredInterceptor'
    exports.service
  ]
  exports.service

exports.service = ($http, $q, $location, authRequiredInterceptor) ->
  user_api_uri = '/api/users'

  class UserManagerService
    get_current_user: ->
      return $q (resolve, reject) ->
        $http.get(user_api_uri + '/current')
        .success (current_user, status, headers, config) ->
          resolve current_user
          return
        .error (data, status, headers, config) ->
          reject()
          return
        return

    login: (username, password) ->
      $http.post('/login', { username: username, password: password })
      .success (data, status, headers, config) ->
        if authRequiredInterceptor.last_intercepted_path?
          $location.path authRequiredInterceptor.last_intercepted_path
        else
          $location.path '/'
        return

  return new UserManagerService
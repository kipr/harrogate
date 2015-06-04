exports.name = 'user_manager_service'

exports.inject = (app) ->
  app.service exports.name, [
    '$http'
    '$q'
    exports.service
  ]
  exports.service

exports.service = ($http, $q) ->
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

  return new UserManagerService
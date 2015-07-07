Io = require 'socket.io-client'

exports.name = 'ProgramService'

exports.inject = (app) ->
  app.service exports.name, [
    '$http'
    '$q'
    '$timeout'
    'AppCatalogProvider'
    exports.service
  ]
  return

exports.service = ($http, $q, $timeout, AppCatalogProvider) ->
  runner_api_uri = '/api/run'

  class ProgramService

    constructor: ->
      @running = null
      return

    run: (project_name) ->

      return $q (resolve, reject) ->
        $http.post(runner_api_uri, {name: project_name})

        .success () ->
          resolve()
          return

        .error () ->
          reject()
          return

        return

    stop: ->

      return $q (resolve, reject) ->
        $http.delete('/api/run/current')

        .success () ->
          resolve()
          return

        .error () ->
          reject()
          return

        return

  service = new ProgramService

  AppCatalogProvider.catalog.then (app_catalog) ->
    events =  app_catalog['Runner']?.event_groups?.runner_events.events
    events_namespace =  app_catalog['Runner']?.event_groups?.runner_events.namespace
    if events?
      socket = Io ':8888' + events_namespace

      socket.on events.starting.id, (name) ->

        $timeout ->
          service.running = name
          return

        return

      socket.on events.ended.id, ->

        $timeout ->
          service.running = null
          return

       return

    return

  return service
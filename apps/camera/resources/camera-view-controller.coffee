CodeMirror = require 'codemirror/lib/codemirror'
Io = require 'socket.io-client'

exports.name = 'CameraViewController'

exports.inject = (app) ->
  app.controller exports.name, [
    '$scope'
    '$http'
    '$location'
    '$timeout'
    'AppCatalogProvider'
    exports.controller
  ]
  return

exports.controller = ($scope, $http, $location, $timeout, AppCatalogProvider) ->

  socket = undefined
  events = undefined
  img_width = undefined
  img_height = undefined

  AppCatalogProvider.catalog.then (app_catalog) ->
    events =  app_catalog['Camera']?.event_groups?.camera_events.events
    events_namespace =  app_catalog['Camera']?.event_groups?.camera_events.namespace
    if events?
      socket = Io ':8888' + events_namespace

      socket.on events.frame_arrived.id, (msg) ->
        img_width = msg.width
        img_height = msg.height

        $scope.$apply ->
          $scope.img_src = '/api/camera?' + new Date().getTime()
          return
       return
    return
  $scope.show_visual = true
  $scope.selected_channel = false

  canvas = document.getElementById('color-picker')
  ctx = canvas.getContext('2d')

  $scope.rect = 
    top_left:
      x: 0
      y: 0
    bottom_right:
      x: canvas.width
      y: canvas.height

  hsv2rgb = (h, s, v) ->
    h /= 60
    s *= 0.01
    v *= 0.01
    i = Math.floor(h)
    f = h - i
    m = v * (1 - s)
    n = v * (1 - (s * f))
    k = v * (1 - (s * (1 - f)))
    rgb = undefined
    switch i
      when 0
        rgb = [
          v
          k
          m
        ]
      when 1
        rgb = [
          n
          v
          m
        ]
      when 2
        rgb = [
          m
          v
          k
        ]
      when 3
        rgb = [
          m
          n
          v
        ]
      when 4
        rgb = [
          k
          m
          v
        ]
      when 5, 6
        rgb = [
          v
          m
          n
        ]
    {
      r: rgb[0] * 255 | 0
      g: rgb[1] * 255 | 0
      b: rgb[2] * 255 | 0
    }


  # http://jsfiddle.net/AbdiasSoftware/wYBEU/
  draw = ->
    s = 100
    v = 100
    bmp = undefined
    data = undefined
    rgb = undefined
    x = undefined
    y = undefined
    l = undefined
    p = undefined
    m = undefined
    mm = undefined
    c = undefined
    f1 = undefined
    f2 = undefined
    wm = undefined
    w = canvas.width
    h = canvas.height
    md = h / 2 + 0.5 | 0
    c0 = undefined
    c1 = undefined
    c2 = undefined
    c3 = undefined
    c4 = undefined
    c5 = undefined
    c6 = undefined
    c0 = hsv2rgb(0, s, v)
    c1 = hsv2rgb(60, s, v)
    c2 = hsv2rgb(120, s, v)
    c3 = hsv2rgb(180, s, v)
    c4 = hsv2rgb(240, s, v)
    c5 = hsv2rgb(300, s, v)
    # make horizontal gradient
    grd = ctx.createLinearGradient(0, 0, w, 0)
    grd.addColorStop 0, 'rgb(' + c0.r + ',' + c0.g + ',' + c0.b + ')'
    grd.addColorStop 0.1667, 'rgb(' + c1.r + ',' + c1.g + ',' + c1.b + ')'
    grd.addColorStop 0.3333, 'rgb(' + c2.r + ',' + c2.g + ',' + c2.b + ')'
    grd.addColorStop 0.5, 'rgb(' + c3.r + ',' + c3.g + ',' + c3.b + ')'
    grd.addColorStop 0.6667, 'rgb(' + c4.r + ',' + c4.g + ',' + c4.b + ')'
    grd.addColorStop 0.8333, 'rgb(' + c5.r + ',' + c5.g + ',' + c5.b + ')'
    grd.addColorStop 1, 'rgb(' + c0.r + ',' + c0.g + ',' + c0.b + ')'
    ctx.fillStyle = grd
    ctx.fillRect 0, 0, w, h
    #make vertical white-to-color and color-to-black part
    bmp = ctx.getImageData(0, 0, w, h)
    data = bmp.data
    mm = 255 / md
    m = mm / 255
    wm = w * 4
    y = 0
    while y < md
      f1 = y * m
      f2 = (md - y) * mm
      l = y * wm
      x = 0
      while x < wm
        p = l + x
        data[p] = f2 + data[p] * f1
        data[p + 1] = f2 + data[p + 1] * f1
        data[p + 2] = f2 + data[p + 2] * f1
        x += 4
      y++
    y = md
    while y < h
      f1 = (h - y) * m
      l = y * wm
      x = 0
      while x < wm
        p = l + x
        data[p] = data[p] * f1
        data[p + 1] = data[p + 1] * f1
        data[p + 2] = data[p + 2] * f1
        x += 4
      y++
    ctx.putImageData bmp, 0, 0

    # draw the bounding box
    ctx.strokeStyle = '#FF0000'
    ctx.strokeRect $scope.rect.top_left.x, $scope.rect.top_left.y,
                   $scope.rect.bottom_right.x, $scope.rect.bottom_right.y

    console.log $scope.rect.top_left.x, $scope.rect.top_left.y,
                $scope.rect.bottom_right.x, $scope.rect.bottom_right.y

    return

  get_position = (el) ->
    xp = 0
    yp = 0
    while el
      xp += el.offsetLeft - (el.scrollLeft) + el.clientLeft
      xp += el.offsetTop - (el.scrollTop) + el.clientTop
      el = el.offsetParent
    {
      x: xp
      y: yp
    }

  # http://stackoverflow.com/questions/2368784/draw-on-html5-canvas-using-a-mouse
  findxy = (res, e) ->
    if res == 'down'

      c_pos = get_position canvas
      console.log e.pageX, e.pageY
      console.log c_pos.x, c_pos.y

      x = e.pageX - c_pos.x
      y = e.pageY - c_pos.y

      if e.button == 2 # right button
         $scope.rect.bottom_right.x = x
         $scope.rect.bottom_right.y = y
      else
         $scope.rect.top_left.x = x
         $scope.rect.top_left.y = y

      draw()

  # canvas.addEventListener 'mousemove', ((e) ->
  #   findxy 'move', e
  #   return
  # ), false
  canvas.addEventListener 'mousedown', ((e) ->
    findxy 'down', e
    return
  ), true
  # canvas.addEventListener 'mouseup', ((e) ->
  #   findxy 'up', e
  #   return
  # ), false
  # canvas.addEventListener 'mouseout', ((e) ->
  #   findxy 'out', e
  #   return
  # ), false

  draw()

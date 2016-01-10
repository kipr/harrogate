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

  $scope.save_config = ->
    channel_config =
      channel_name: 'Channel_1'
      th: $scope.channel.hue.to
      ts: $scope.channel.saturation.to
      tv: $scope.channel.value.to
      bh: $scope.channel.hue.from
      bs: $scope.channel.saturation.from
      bv: $scope.channel.value.from

    $http.post('/api/camera/settings',  {channel_config: channel_config})


  # TODO: Get the current values
  $scope.channel = 
    hue:
      from: 40
      to: 80
    saturation:
      from: 30
      to:70
    value:
      from: 80
      to: 120

  canvas = document.getElementById('color-picker')
  canvas_container = canvas.parentElement

  ctx = canvas.getContext '2d'
  ctx.canvas.width  = canvas_container.offsetWidth
  ctx.canvas.height = canvas_container.offsetHeight

  color_picker_bounding_rect = 
    top_left:
      x: 0
      y: 0
      color: 'white'
    bottom_right:
      x: canvas.width
      y: canvas.height
      color: 'black'

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

  # http://www.javascripter.net/faq/rgb2hsv.htm
  rgb2hsv = (r, g, b) ->
    computedH = 0
    computedS = 0
    computedV = 0
    if r == null or g == null or b == null or isNaN(r) or isNaN(g) or isNaN(b)
      alert 'Please enter numeric RGB values!'
      return
    if r < 0 or g < 0 or b < 0 or r > 255 or g > 255 or b > 255
      alert 'RGB values must be in the range 0 to 255.'
      return
    r = r / 255
    g = g / 255
    b = b / 255
    minRGB = Math.min(r, Math.min(g, b))
    maxRGB = Math.max(r, Math.max(g, b))
    # Black-gray-white
    if minRGB == maxRGB
      computedV = minRGB
      return [
        0
        0
        computedV
      ]
    # Colors other than black-gray-white:
    d = if r == minRGB then g - b else if b == minRGB then r - g else b - r
    h = if r == minRGB then 3 else if b == minRGB then 1 else 5
    computedH = 60 * (h - (d / (maxRGB - minRGB)))
    computedS = (maxRGB - minRGB) / maxRGB
    computedV = maxRGB
    [
      Math.round computedH
      Math.round computedS*100
      Math.round computedV*100
    ]



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
    bb_width = color_picker_bounding_rect.bottom_right.x - color_picker_bounding_rect.top_left.x
    bb_height = color_picker_bounding_rect.bottom_right.y - color_picker_bounding_rect.top_left.y

    ctx.strokeStyle = 'black'
    ctx.strokeRect color_picker_bounding_rect.top_left.x, color_picker_bounding_rect.top_left.y, bb_width, bb_height

    # draw the handles
    ctx.beginPath()
    ctx.arc color_picker_bounding_rect.top_left.x, color_picker_bounding_rect.top_left.y, 15, 0, 2*Math.PI, false
    ctx.lineWidth = 2
    ctx.strokeStyle = 'black'
    ctx.stroke()
    ctx.fillStyle =  color_picker_bounding_rect.top_left.color
    ctx.fill()

    ctx.beginPath()
    ctx.arc color_picker_bounding_rect.bottom_right.x, color_picker_bounding_rect.bottom_right.y, 15, 0, 2*Math.PI, false
    ctx.lineWidth = 2
    ctx.strokeStyle = 'black'
    ctx.stroke()
    ctx.fillStyle =  color_picker_bounding_rect.bottom_right.color
    ctx.fill()

    return


  # set the position
  canvas.onmousedown = (e) ->
    [x, y] =
    if e.offsetX?
      [e.offsetX, e.offsetY]
    else
      [e.layerX - e.currentTarget.offsetLeft, e.layerY - e.currentTarget.offsetTop]

    # calculate the distance to the current handle points
    bottom_right_distance = Math.sqrt( Math.pow(color_picker_bounding_rect.bottom_right.x - x, 2)
                                     + Math.pow(color_picker_bounding_rect.bottom_right.x - x, 2) )

    top_left_distance = Math.sqrt( Math.pow(color_picker_bounding_rect.top_left.x - x, 2)
                                 + Math.pow(color_picker_bounding_rect.top_left.x - x, 2) )

    # update the hsv values of this point
    [r, g, b] = ctx.getImageData(x, y, 1, 1).data
    [h, s, v] = rgb2hsv r, b, g

    # set the closest handle to the new x,y
    $scope.$apply ->
      if bottom_right_distance < top_left_distance
        color_picker_bounding_rect.bottom_right.x = x
        color_picker_bounding_rect.bottom_right.y = y
        color_picker_bounding_rect.bottom_right.color = 'rgb(' + r + ',' + g + ',' + b + ')'

        $scope.channel.hue.to = h
        $scope.channel.saturation.to = s
        $scope.channel.value.to = v

      else
        color_picker_bounding_rect.top_left.x = x
        color_picker_bounding_rect.top_left.y = y
        color_picker_bounding_rect.top_left.color = 'rgb(' + r + ',' + g + ',' + b + ')'

        $scope.channel.hue.from = h
        $scope.channel.saturation.from = s
        $scope.channel.value.from = v

    draw()

  draw()

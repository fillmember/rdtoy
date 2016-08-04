THREE = require 'three'
$ = require 'jquery'
EventEmitter = require('events').EventEmitter

MouseUtils = require './utils/MouseUtils'

PI2 = 2 * Math.PI

class DrawPad
	constructor: ({
		@canvas = document.createElement('canvas')
		@width = 1024
		@height = 512
		@backgroundColor
	}) ->
		@context = @canvas.getContext("2d")
		@width = @canvas.width
		@height = @canvas.height

		@mouseEventManager = MouseUtils.bind
			dom  : @canvas
			down : (evt) => @onMouseDown(evt)
			up   : (evt) => @onMouseUp(evt)
			move : (evt) => @onMouseMove(evt)
			enter: (evt) => @showCursor()
			leave: (evt) => @onMouseUp(evt) ; @hideCursor()

		@fill @backgroundColor

		@setSize @width , @height

		@events = new EventEmitter

		# DrawStyle

		@brushColor = new THREE.Color 0.25 , 0.6 , 0.05
		@brushSize = 25
		@brushSoftness = 1
		@brushOpacity = 0.1

		# Interaction

		@drawing = false
		@history = {
			x: undefined
			y: undefined
		}

	setDrawStyle: (size = @brushSize, color = @brushColor.getStyle(), feather = @brushSoftness ) ->
		# Set Properties
		@brushColor.setStyle color
		@brushSize = size
		@brushSoftness = feather
		# Set Context
		@context.lineCap = "round"
		@context.lineJoin = "round"
		@context.lineWidth = size
		@context.strokeStyle = color

	setHistory: ( x , y ) ->
		@history.x = x
		@history.y = y

	setSize: (w = @width, h = @height) ->
		@width = w
		@height = h
		@canvas.width = w
		@canvas.height = h
		if @backgroundColor
			@fill @backgroundColor

	drawOn: ( pos ) ->
		if not @history.x? or not @history.y?
			'do nothing'
		else
			@line @history , pos
		@setHistory pos.x , pos.y

	fill: ( r , g , b , a = 1 ) ->
		if typeof r is 'string'
			@backgroundColor = r
		else if typeof r is 'number'
			r = Math.round(r * 100)
			g = Math.round(g * 100)
			b = Math.round(b * 100)
			text = "rgba(#{r}%,#{g}%,#{b}%,#{a})"
			@backgroundColor = text
		@context.rect 0 , 0 , @width , @height
		@context.fillStyle = @backgroundColor
		@context.fill()

	line: ( from , to ) ->
		v = new THREE.Vector2 to.x - from.x , to.y - from.y
		d = v.length()
		i = 0
		step = 1
		while i < d
			s = i / d
			ns = 1 - s
			x = from.x * s + to.x * ns
			y = from.y * s + to.y * ns
			@dot x , y
			i += step

	dot: (x,y) ->
		# short hands
		ctx = @context
		w = @brushSize
		# color
		r = Math.round( @brushColor.r * 100 ) + "%"
		g = Math.round( @brushColor.g * 100 ) + "%"
		b = Math.round( @brushColor.b * 100 ) + "%"
		str = "rgba(#{r},#{g},#{b},"
		# fillStyle
		grad = ctx.createRadialGradient x , y , 0 , x , y , w
		grad.addColorStop 1 - @brushSoftness , str + @brushOpacity + ")"
		grad.addColorStop 1 , str + "0)"
		ctx.fillStyle = grad
		# punch
		ctx.beginPath()
		ctx.arc x , y , w , 0 , PI2
		ctx.fill()
		ctx.closePath()

	drawImage: (img) ->
		@context.drawImage img , 0 , 0 , @width , @height

	drawData: (data, cb) ->
		img = new Image()
		img.onload = =>
			@drawImage img
			if cb? then cb()
		img.src = data

	drawOff: ->
		@drawing = false
		@setHistory()
		@events.emit "end"

	onMouseDown: (evt) ->
		@drawing = true
		@setDrawStyle()
		@events.emit "start"
		@events.emit "drawing"

	onMouseUp: (evt) ->
		@drawOff()

	onMouseMove: (evt) ->
		pos = MouseUtils.getRelativePos( evt.target , evt.clientX , evt.clientY )
		pos = x : pos.x * @width , y : pos.y * @height
		@cursorTo pos.x , pos.y
		if not @drawing then return
		@drawOn pos
		@events.emit "drawing"

	hideCursor: (remove) ->
		@cursor.fadeOut 50 , -> if remove then @cursor.remove()
	showCursor: (x,y) ->
		if not @cursor? then @setupCursor()
		@cursor.fadeIn 50
		if x? and y? then @cursorTo x , y

	cursorTo: (x,y) ->
		size = @brushSize * 2
		x = x - @brushSize
		y = y - @brushSize
		TweenLite.set @cursor , {
			x : x
			y : y
			borderColor : @brushColor.getStyle()
			width : size
			height : size
		}
		blur = "blur(#{ @brushSoftness }px)"
		@cursor.css "filter" , blur
		@cursor.css "webkitFilter" , blur

	setupCursor: () ->
		# cursor
		@cursor = $ '<div class="cursor"></div>'
		$ @canvas
			.addClass 'hideCursor'
			.parent()
				.append @cursor
	
	showDebugInterface: (gui) ->
		f = gui.addFolder "DrawPad"
		f.open()
		f.add( @ , 'brushSoftness' , 0 , 1 )

module.exports = DrawPad
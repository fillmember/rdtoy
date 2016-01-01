THREE = require 'three'
$ = require 'jquery'
EventEmitter = require('events').EventEmitter

MouseUtils = require './utils/MouseUtils'

class DrawPad
	constructor: ({
		@canvas = document.createElement('canvas')
		@width = 1024
		@height = 512
	}) ->
		@context = @canvas.getContext("2d")

		@mouseEventManager = MouseUtils.bind
			dom  : @canvas
			down : @onMouseDown.bind this
			up   : @onMouseUp.bind this
			move : @onMouseMove.bind this

		@setSize @width , @height

		@events = new EventEmitter

		# DrawStyle

		@drawColor = new THREE.Color 0.25 , 0.5 , 0
		@drawSize = 25
		@drawFeather = 0

		# Interaction

		@drawing = false
		@history = {
			x: undefined
			y: undefined
		}

	setDrawStyle: (size = @drawSize, color = @drawColor.getStyle(), feather = @drawFeather ) ->
		# Set Properties
		@drawColor.setStyle color
		@drawSize = size
		@drawFeather = feather
		# Set Context
		@context.lineCap = "round"
		@context.lineJoin = "round"
		@context.lineWidth = size
		@context.strokeStyle = color
		# @context.globalCompositeOperation = "overlay"
		# @context.globalCompositeOperation = "screen"

	setHistory: ( x , y ) ->
		@history.x = x
		@history.y = y

	setSize: (w = @width, h = @height) ->
		@canvas.width = w
		@canvas.height = h

	drawOn: ( pos ) ->
		if not @history.x? or not @history.y?
			'do nothing'
		else
			@line @history , pos
		@setHistory pos.x , pos.y

	fill: ( r , g , b , a = 1 ) ->
		r = Math.round(r * 100)
		g = Math.round(g * 100)
		b = Math.round(b * 100)
		text = "rgba(#{r}%,#{g}%,#{b}%,#{a})"
		@context.rect 0 , 0 , @width , @height
		@context.fillStyle = text
		@context.fill()

	line: ( from , to ) ->
		v = new THREE.Vector2 to.x - from.x , to.y - from.y
		d = v.length()
		i = 0
		step = 2
		while i < d
			s = i / d
			ns = 1 - s
			x = from.x * s + to.x * ns
			y = from.y * s + to.y * ns
			@dot x , y
			i += step

	dot: (x,y) ->
		ctx = @context
		w = @drawSize
		f = @drawFeather
		r = Math.round( @drawColor.r * 100 ) + "%"
		g = Math.round( @drawColor.g * 100 ) + "%"
		b = Math.round( @drawColor.b * 100 ) + "%"
		# draw
		grad = ctx.createRadialGradient x , y , 0 , x , y , w
		grad.addColorStop f , "rgba(#{r},#{g},#{b},1)"
		grad.addColorStop 1 , "rgba(#{r},#{g},#{b},0)"
		ctx.fillStyle = grad
		# punch
		@context.beginPath()
		@context.arc x , y , @drawSize , 0 , 2 * Math.PI
		@context.fill()
		@context.closePath()

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
		if not @drawing then return
		@drawOn MouseUtils.getPos( evt.target , evt.clientX , evt.clientY )
		@events.emit "drawing"
	
	showDebugInterface: (gui) ->
		f = gui.addFolder "DrawPad"
		f.open()
		f.add( @drawColor , "r" , 0 , 0.8 ).name("brush:birth rate")
		f.add( @drawColor , "g" , 0 , 0.7 ).name("brush:kill rate")
		f.add( @ , "drawSize" , 5 , 100 ).name("brush:size")

module.exports = DrawPad
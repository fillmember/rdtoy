gsap = require 'gsap'
window.THREE = THREE = require 'three'
window.$ = $ = require 'jquery'
window.UI = UI = require './utils/InterfaceUtils.coffee'
MouseUtils = require './utils/MouseUtils'
ReactiveDiffusionSimulator = require './ReactiveDiffusionSimulator'
EnvironmentMap = require './EnvironmentMap'

# Reactive Diffusion Simulator
ready = new ReactiveDiffusionSimulator
	canvas: $('#readyCanvas').get(0)

ready.mouseEventManager = MouseUtils.bind
	dom: ready.renderer.domElement
	down: (evt) ->
		ready.drawOn MouseUtils.getMouseUV evt.target , evt.clientX , evt.clientY
	move: (evt, manager) ->
		if not manager.mouseButtonPressed then return
		ready.drawOn MouseUtils.getMouseUV evt.target , evt.clientX , evt.clientY
	up: -> ready.drawOff()

window.ready = ready

# Environment Map
envmap = new EnvironmentMap
	canvas: $('#drawCanvas').get(0)
	video: $('#envmapVideo').get(0)
ready.setEnvMap envmap.texture

ready.events.on 'step' , -> if envmap.video is true then envmap.updateTexture()

# Helper Function
setCanvasSize = (w,h) ->
	ready.setSize w , h
	envmap.setSize ready.width , ready.height
	$('#canvasContainer')
		.width ready.width
		.height ready.height

setCanvasSize 512 , 512

# #######################
# Objects, Queries
# #######################
$controls     = $('#controls')

# #######################
# General Interface
# #######################
hideDrawCanvas = ->
	envmap.canvas.style.display = "none"
	envmap.videoTag.style.display = "none"
showDrawCanvas = ->
	envmap.canvas.style.display = "block"
	envmap.videoTag.style.display = "block"
hideDrawCanvas()

toggleCursor = (bool) ->
	$(envmap.canvas).toggleClass 'hideCursor' , bool
	$('.cursor').css 'opacity' , if bool then 1 else 0
setBothBrushSize = (v) ->
	ready.uniforms.brushSize.value = v
	envmap.brushSize = v * 0.5
setBothBrushSize defaultBrushSize = 20

$controls.append UI.section
	icon: 'fa-smile-o'
	name: 'general'
	child: [
		UI.item [
			UI.btnGroup [
				UI.button
					icon: 'fa-flask'
					name: 'simulation'
					solo: true
					checkbox: true
					checked: true
					group: 'drawDecision'
					root: $controls
					action: hideDrawCanvas
				UI.button
					icon: 'fa-map-o'
					name: 'map'
					solo: true
					checkbox: true
					group: 'drawDecision'
					root: $controls
					action: showDrawCanvas
			]
			UI.slider
				icon: 'fa-arrows-h'
				name: 'width'
				object: {n: Math.log2(ready.width) - 6}
				property: 'n'
				min: 1
				max: 5
				display: (v) -> v + 'px'
				transform: (v) -> Math.pow 2 , (6 + parseInt v)
				onChange: (v) -> setCanvasSize v , ready.height
			UI.slider
				icon: 'fa-arrows-v'
				name: 'height'
				object: {n: Math.log2(ready.height) - 6}
				property: 'n'
				min: 1
				max: 5
				display: (v) -> v + 'px'
				transform: (v) -> Math.pow 2 , (6 + parseInt v)
				onChange: (v) -> setCanvasSize ready.width , v
			UI.col [
				UI.toggle
					name: 'show cursor'
					checked: true
					action: toggleCursor
				UI.toggle
					name: 'show map'
					checked: true
					action: (v) -> $(envmap.canvas).animate { opacity: if v then 0.5 else 0 } , 100
			]
		]
		UI.item [
			UI.slider
				icon: 'fa-paint-brush'
				name: 'brush size'
				object: {b:defaultBrushSize}
				property: 'b'
				min: 5
				max: 200
				onInput: (v) -> setBothBrushSize v
		]
	]

# #######################
# Ready Interface
# #######################
$sectionReady = UI.section({ icon: 'fa-flask', name: 'ready' })
$controls.append $sectionReady
ready.setupInterface $sectionReady , $controls

# #######################
# Envmap Interface
# #######################
$sectionEnv = UI.section({ icon: 'fa-map-o', name: 'environment' })
$controls.append $sectionEnv
envmap.setupInterface $sectionEnv , $controls

# #######################
# Render Interface
# #######################
Exporter = require './Exporter.coffee'

exporter = new Exporter
	simulator : ready
	canvas    : ready.renderer.domElement
	UIRoot    : $controls

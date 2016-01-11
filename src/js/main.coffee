THREE = require 'three'
$ = require 'jquery'
_ = require 'lodash'

MouseUtils = require './utils/MouseUtils'
ReactiveDiffusionSimulator = require './ReactiveDiffusionSimulator'
EnvironmentMap = require './EnvironmentMap'
AnimationExporter = require './AnimationExporter'

# Ready
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

envmap = new EnvironmentMap
	canvas: $('#drawCanvas').get(0)
	video: $('#envmapVideo').get(0)
ready.setEnvMap envmap.texture

ready.events.on 'step' , ->
	if envmap.video is true
		envmap.updateTexture()

setCanvasSize = (w,h) ->
	ready.setSize w , h
	envmap.setSize ready.width , ready.height
	$('#canvasContainer')
		.width ready.width
		.height ready.height

setCanvasSize 512 , 512

animExport = new AnimationExporter
	canvas: ready.renderer.domElement
# Mode
exportSteps = ->
	animExport.connect ->
		from = animExport.options.from
		animExport.renderVideo from , from + 1
animExport.events.on 'modechange' , (mode) ->
	
	if mode is animExport.MODES.MODE_STARTONEXPORT
	
		if ready.running then ready.setRunning false
	
	if mode is animExport.MODES.MODE_EXPORTSTEPS
	
		if ready.running then ready.setRunning false
		ready.events.on 'step' , exportSteps
	
	else
	
		ready.events.removeListener 'step' , exportSteps

animExport.events.on 'start' , ->
	if animExport.options.mode is animExport.MODES.MODE_STARTONEXPORT
		ready.setRunning true
animExport.events.on 'finish' , ->
	if animExport.options.mode is animExport.MODES.MODE_STARTONEXPORT
		ready.setRunning false
		

# DEV GUI
# dat = require './../vendor/dat.gui'
# gui = new dat.GUI()
# envmap.showDebugInterface gui

# GUI
UI = require './utils/InterfaceUtils'
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

setBothBrushSize = (v) ->
	ready.uniforms.brushSize.value = v
	envmap.brushSize = v * 0.5
setBothBrushSize defaultBrushSize = 20

$controls.append UI.section
	icon: 'fa-smile-o'
	name: 'general'
	child: [
		UI.item [
			UI.itemHeader 'Draw on...'
			UI.btnGroup [
				UI.button
					icon: 'fa-flask'
					name: 'sim map'
					solo: true
					checkbox: true
					checked: true
					group: 'drawDecision'
					root: $controls
					action: hideDrawCanvas
				UI.button
					icon: 'fa-map-o'
					name: 'env map'
					solo: true
					checkbox: true
					group: 'drawDecision'
					root: $controls
					action: showDrawCanvas
			]
			UI.col [
				UI.toggle
					name: 'show brush'
					checked: true
					action: (v) ->
						if v
							$(envmap.canvas).addClass 'hideCursor'
							$('.cursor').css 'opacity' , 1
						else
							$('.hideCursor').removeClass 'hideCursor'
							$('.cursor').css 'opacity' , 0
				UI.toggle
					name: 'show env map'
					checked: true
					action: (v) -> 
						$(envmap.canvas).animate {
							opacity: if v then 0.5 else 0
						} , 100
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
		UI.item [
			# UI.itemHeader 'texture size'
			UI.slider
				icon: 'fa-arrows-h'
				name: 'width'
				object: {n: Math.log2(ready.width) - 6}
				property: 'n'
				min: 1
				max: 5
				display: (v) -> v + 'px'
				transform: (v) ->
					v = 6 + parseInt v
					return Math.pow 2 , v
				onChange: (v, slider) ->
					setCanvasSize v , ready.height
			UI.slider
				icon: 'fa-arrows-v'
				name: 'height'
				object: {n: Math.log2(ready.height) - 6}
				property: 'n'
				min: 1
				max: 5
				display: (v) -> v + 'px'
				transform: (v) ->
					v = 6 + parseInt v
					return Math.pow 2 , v
				onChange: (v, slider) ->
					setCanvasSize ready.width , v
		]
	]

# #######################
# Ready Interface
# #######################
$sectionReady = UI.section
	icon: 'fa-flask'
	name: 'ready'
$controls.append $sectionReady
ready.setupInterface $sectionReady , $controls

# #######################
# Envmap Interface
# #######################
$sectionEnv = UI.section
	icon: 'fa-map-o'
	name: 'environment'
$controls.append $sectionEnv
envmap.setupInterface $sectionEnv , $controls

# #######################
# Render Interface
# #######################

$controls.append animExport.setupInterface UI.section({icon:'fa-motorcycle',name:'render'}) , $controls

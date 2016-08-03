THREE = require 'three'
$ = require 'jquery'
_ = require 'lodash'

MouseUtils = require './utils/MouseUtils'
ReactiveDiffusionSimulator = require './ReactiveDiffusionSimulator'
EnvironmentMap = require './EnvironmentMap'
AnimationExporter = require './AnimationExporter'

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

# animExport = new AnimationExporter
# 	canvas: ready.renderer.domElement
# # Mode
# exportSteps = ->
# 	animExport.connect ->
# 		from = animExport.options.from
# 		animExport.renderVideo from , from + 1
# animExport.events.on 'modechange' , (mode) ->
	
# 	if mode is animExport.MODES.MODE_STARTONEXPORT
	
# 		if ready.running then ready.setRunning false
	
# 	if mode is animExport.MODES.MODE_EXPORTSTEPS
	
# 		if ready.running then ready.setRunning false
# 		ready.events.on 'step' , exportSteps
	
# 	else
	
# 		ready.events.removeListener 'step' , exportSteps

# animExport.events.on 'start'  , -> if animExport.options.mode is animExport.MODES.MODE_STARTONEXPORT then ready.setRunning true
# animExport.events.on 'finish' , -> if animExport.options.mode is animExport.MODES.MODE_STARTONEXPORT then ready.setRunning false
		

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
# $controls.append animExport.setupInterface UI.section({icon:'fa-motorcycle',name:'render'}) , $controls

require './../vendor/whammy/whammy.js'
require './../vendor/ccapture/CCapture.js'
EventEmitter = require('events').EventEmitter

capture = 
	data: []
	events: new EventEmitter()
	status:
		capturing: no
	settings:
		captureWhileDrawing: false
	add: ->
		capture.data.push ready.renderer.domElement.toDataURL 'image/webp'
		capture.UIActions.updateUI()
	UI: {}
	UIActions:
		updateUI: -> capture.events.emit 'ui'
		disable: (dom) -> capture.UI[dom].prop 'disabled' , true
		enable: (dom) -> capture.UI[dom].prop 'disabled' , false
		toggleRecordState: (dom,bool) -> capture.UI[dom].toggleClass 'pulsing red' , bool

ready.events.on 'run' , ->if capture.status.capturing and ready.running then capture.add()
ready.events.on 'draw' , ->if not capture.status.capturing and capture.settings.captureWhileDrawing then capture.add()

$controls.append UI.section
	icon: 'fa-truck'
	name: 'render'
	child: [
		UI.item [
			capture.UI.bufferDisplay = UI.display
				icon: 'fa-cloud'
				name: 'buffer'
				object: capture.data
				property: 'length'
				eventEmitter: capture.events
				eventName: 'ui'
				display: (v)->v+' frame'+(if v > 1 then 's' else '')+' in buffer'
			UI.btnGroup [
				capture.UI.captureButton = UI.button
					name: 'capture'
					checkbox: true
					action: (v)->
						capture.status.capturing = v
						if capture.status.capturing
							capture.UIActions.toggleRecordState 'captureButton' , yes
							capture.UIActions.toggleRecordState 'bufferDisplay' , yes
							ready.setRunning true
						else
							capture.UIActions.toggleRecordState 'captureButton' , no
							capture.UIActions.toggleRecordState 'bufferDisplay' , no
							ready.setRunning false
							capture.UIActions.updateUI()
				capture.UI.getWebMButton = UI.button
					name: 'save webm'
					action: ->
						blob = Whammy.fromImageArray capture.data , 30 , false
						url = URL.createObjectURL blob
						window.open url
				capture.UI.clearBufferButton = UI.button
					name: 'clear buffer'
					action: ->
						capture.data.length = 0
						capture.UIActions.updateUI()
			]
		]
		UI.item [
			UI.itemHeader [
				UI.icon 'fa-link'
				UI.spanText 'auto capture when...'
			]
			UI.btnGroup [
				UI.button
					icon: 'fa-paint-brush'
					name: 'drawing'
					checkbox: true
					checked: capture.settings.captureWhileDrawing
					group: 'captureConditionGroup'
					root: $controls
					action: (v) -> capture.settings.captureWhileDrawing = v
			]
		]
	]









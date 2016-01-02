THREE = require 'three'
$ = require 'jquery'
dat = require './../vendor/dat.gui.js'
# FileReader = require './../vendor/FileReader.js'

MouseUtils = require './utils/MouseUtils'
DrawPad = require './DrawPad'
ReactiveDiffusionSimulator = require './ReactiveDiffusionSimulator'

gui = new dat.GUI
ready = new ReactiveDiffusionSimulator
	width: 512
	height: 512
drawpad = new DrawPad
	width: 512
	height: 512

$body = $ 'body'
$body.append drawpad.canvas
$body.append ready.renderer.domElement

ready.showDebugInterface gui
ready.presentMaterial.setupInterface( $body )
drawpad.showDebugInterface gui
drawpad.fill 0.31 , 0.6 , 0.1

drawTex = new THREE.Texture drawpad.canvas
drawTex.needsUpdate = true
drawpad.events.on "drawing" , => drawTex.needsUpdate = true
	
ready.setEnvMap drawTex

ready.mouseEventManager = MouseUtils.bind
	dom: ready.renderer.domElement
	down: (evt) ->
		ready.drawOn MouseUtils.getMouseUV evt.target , evt.clientX , evt.clientY
	move: (evt, manager) ->
		if not manager.mouseButtonPressed then return
		ready.drawOn MouseUtils.getMouseUV evt.target , evt.clientX , evt.clientY
	up: -> ready.drawOff()


render = ->
	ready.step()
	ready.present()
	requestAnimationFrame render
render()

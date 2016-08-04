EventEmitter = require('events').EventEmitter
DefaultPresentMaterial = require './GradientMappingMaterial'
TextureHelper = require './helpers/TextureHelper'

brushOff = new THREE.Vector2 -1 , -1
plane = new THREE.PlaneGeometry 1 , 1
camPosition = new THREE.Vector3 0 , 0 , 100
renderTargetOptions = {
	minFilter : THREE.LinearFilter
	magFilter : THREE.LinearFilter
	format    : THREE.RGBAFormat
	type      : THREE.FloatType
	wrapS     : THREE.RepeatWrapping
	wrapT     : THREE.RepeatWrapping
	depthBuffer : false
	stencilBuffer : false
}

maxTextureSize = 1024

class ReactiveDiffusionSimulator
	constructor: ({
		@width = 1024
		@height = 512
		presentMaterial = new DefaultPresentMaterial
		canvas
		autorun = true
	}) ->
		# Programming
		@events = new EventEmitter()
		# THREE Important Objects
		@renderer = new THREE.WebGLRenderer
			canvas: canvas
			preserveDrawingBuffer: true
		@camera = new THREE.OrthographicCamera -0.5, 0.5, 0.5, -0.5, -1000, 1000
		@camera.position.copy camPosition
		@mesh = new THREE.Mesh plane , @mat
		@scene = new THREE.Scene
		@scene.add @mesh
		# Texture : Uniforms
		@uniforms = 
			tSource : {type: "t", value: undefined}
			tEnv    : {type: "t", value: undefined}

			step    : {type: "v2", value: new THREE.Vector2( 0.1 , 0.1 )}

			delta   : {type: "f" , value: 0.900}
			feedFactor : {type: "f" , value: 0.1}
			killFactor : {type: "f" , value: 0.1}

			brush   : {type: "v2", value: brushOff.clone()}
			brushSize : {type: "f", value: 10}
			brushColor : {type: "v2", value: new THREE.Vector2( 0.7 , 0.5 )}
		# Texture : Objects
		@textureHelper = new TextureHelper
			renderer: @renderer
			camera: @camera
		@textureHelper.setRenderTarget @width , @height , renderTargetOptions
		@tex1 = @textureHelper.getSolidRenderTarget 1 , 1 , 0
		@tex2 = @textureHelper.getSolidRenderTarget 1 , 1 , 0
		# Shader
		vShader = require './../shader/standard.vs.glsl'
		fShader = require './../shader/gs.fs.glsl'
		@mat = new THREE.ShaderMaterial
			uniforms: @uniforms
			vertexShader: vShader
			fragmentShader: fShader
		# Simulation Configuration
		@running = false
		@stepSize = 1
		@subStepCount = 8
		@iteration = 0
		# Present
		@presentMaterial = presentMaterial
		# Init Sequence
		@setSize @width , @height
		if autorun
			@running = true
		@run()

	setRunning: (t) ->
		@running = t
		$('#ready-run-button').data('ui').update @running

	setSize: ( w = @width , h = @height ) ->
		texw = Math.min maxTextureSize , 0.5 * w
		texh = Math.min maxTextureSize , 0.5 * h
		ratio = texh / texw
		@width = w
		@height = w * ratio
		@renderer.setSize w , w * ratio
		@textureHelper.setSize w , w * ratio
		@tex1.setSize texw , texh
		@tex2.setSize texw , texh
		@uniforms.step.value.set @stepSize / texw , @stepSize / texh

	fill: ( a , b ) ->
		@tex1 = @textureHelper.getSolidRenderTarget a , b , 0
		@tex2 = @tex1.clone()

	clear: -> @fill 1 , 0

	setEnvMap: (tex) -> @uniforms.tEnv.value = tex

	setMap: (tex) ->
		mat = new THREE.MeshBasicMaterial map : tex
		@mesh.material = mat
		@renderer.render @scene , @camera , @tex1

	drawOn: ( x , y ) ->
		if arguments.length is 2
			@uniforms.brush.value.set x , y
		else
			@uniforms.brush.value.copy x
		if not @running
			@mesh.material = @mat
			@subStep 1
		@events.emit 'draw'

	drawOff: -> @uniforms.brush.value = brushOff.clone()

	step: () ->
		@events.emit 'step'
		@mesh.material = @mat
		@subStep @subStepCount

	subStep: ( n ) ->
		if n <= 0 then return
		if @iteration % 2 is 0
			@uniforms.tSource.value = @tex1
			@renderer.render @scene , @camera , @tex2
			@uniforms.tSource.value = @tex2
		else
			@uniforms.tSource.value = @tex2
			@renderer.render @scene , @camera , @tex1
			@uniforms.tSource.value = @tex1
		@iteration += 1
		# Recursive
		n -= 1
		@subStep n

	present: () ->
		@mesh.material = @presentMaterial.material
		@renderer.render @scene , @camera

	run: () ->
		if @running then @step()
		@present()
		@events.emit 'run' , performance.now()
		window.requestAnimationFrame => @run()

	pause: () -> @running = false

	setupInterface: ( section , root , special ) ->
		# Buttons
		section.append UI.item UI.btnGroup [
			UI.button
				id       : 'ready-run-button'
				icon     : 'fa-futbol-o'
				name     : 'run'
				checkbox : true
				checked  : @running
				action   : (t, btn) => @running = t
			UI.button
				icon     : 'fa-step-forward'
				name     : 'step'
				action   : => @step()
			UI.button
				name     : 'clear'
				icon     : 'fa-times'
				action   : =>
					@clear()
					if not @running then @step()
		]
		# Sliders
		section.append UI.item [
			UI.slider
				name     : 'speed'
				icon     : 'fa-clock-o'
				object   : @
				property : 'subStepCount'
				min      : 1
				max      : 32
				step     : 1
				display: (v) -> v + 'x'
			UI.slider
				name     : 'feed'
				icon     : 'fa-plus-circle'
				object   : @uniforms.feedFactor
				property : 'value'
				min      : 0
				max      : 0.15
				step     : 0.01
				display  : (v) -> Math.round(1000 * v) + '%'
			UI.slider
				name     : 'kill'
				icon     : 'fa-bolt'
				object   : @uniforms.killFactor
				property : 'value'
				min      : 0
				max      : 0.15
				step     : 0.01
				display  : (v) -> Math.round(1000 * v) + '%'
			UI.slider
				name     : 'step'
				icon     : 'fa-search'
				object   : @
				property : "stepSize"
				min      : 0.125
				max      : 6
				step     : 0.125
				onInput  : =>
					texw = Math.min maxTextureSize , 0.5 * @width
					texh = Math.min maxTextureSize , 0.5 * @height
					@uniforms.step.value.set @stepSize / texw , @stepSize / texh
				display: (v) -> v + 'x'
		]

		@presentMaterial.setupInterface section

	showDebugInterface: ( gui ) ->
		f = gui.addFolder "Reactive Diffusion Simulator"
		f.open()
		f.add( @ , 'subStepCount' , 0 , 64 ).step(1)
		f.add( @uniforms.brushSize , 'value' , 1 , 32 ).name('brush size')
		f.add( @uniforms.feedFactor , 'value' , 0 , 0.1 ).step(0.001).name('feed')
		f.add( @uniforms.killFactor , 'value' , 0 , 0.1 ).step(0.001).name('kill')
		f.add( @ , 'stepSize' , 0.5 , 10 ).step(0.5).onChange => @setSize()
		f.add( @ , 'clear' )


module.exports = ReactiveDiffusionSimulator
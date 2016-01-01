THREE = require 'three'
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

class ReactiveDiffusionSimulator
	constructor: ({
		@width = 1024
		@height = 512
		presentMaterial = new DefaultPresentMaterial
		canvas
	}) ->
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
		@tex1 = @textureHelper.getSolidRenderTarget 1 , 0 , 0
		@tex2 = @textureHelper.getSolidRenderTarget 1 , 0 , 0
		# Shader
		vShader = require './../shader/standard.vs.glsl'
		fShader = require './../shader/gs.fs.glsl'
		@mat = new THREE.ShaderMaterial
			uniforms: @uniforms
			vertexShader: vShader
			fragmentShader: fShader
		# Simulation Configuration
		@stepSize = 1
		@subStepCount = 8
		@iteration = 0
		# Present
		@presentMaterial = presentMaterial
		# Init Sequence
		@setSize @width , @height

	setSize: ( w = @width , h = @height ) ->
		@renderer.setSize(w, h);
		w *= 0.5
		h *= 0.5
		@textureHelper.setSize w , h
		@tex1.setSize w , h
		@tex2.setSize w , h
		@uniforms.step.value.set @stepSize / w , @stepSize / h

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
	drawOff: -> @uniforms.brush.value = brushOff.clone()

	step: () ->
		@mesh.material = @mat
		@subStep @subStepCount

	subStep: ( n ) ->
		if n <= 0 then return
		if @iteration % 2 is 0 #@toggle
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






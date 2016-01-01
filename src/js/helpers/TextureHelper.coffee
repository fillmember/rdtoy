THREE = require 'three'

constantMaterial = new THREE.MeshBasicMaterial color : 0
constantPlane = new THREE.PlaneGeometry 1 , 1

defaultWidth = 512
defaultHeight = 512
defaultOptions =
	minFilter : THREE.LinearFilter
	magFilter : THREE.LinearFilter
	format    : THREE.RGBAFormat
	type      : THREE.FloatType
	wrapS     : THREE.RepeatWrapping
	wrapT     : THREE.RepeatWrapping

class TextureHelper
	constructor: ({
		@renderer
		@camera = new THREE.OrthographicCamera -0.5, 0.5, 0.5, -0.5, -1000, 1000
		@scene = new THREE.Scene
	})->
		if not @renderer?
			@renderer = new THREE.WebGLRenderer
				preserveDrawingBuffer: true
				alpha: true
			@renderer.setSize defaultWidth , defaultHeight
		@mesh = new THREE.Mesh constantPlane , constantMaterial
		@scene.add @mesh

	setRenderTarget: ( w=defaultWidth , h=defaultHeight , o=defaultOptions ) ->
		if w instanceof THREE.WebGLRenderTarget
			@renderTarget = w.clone()
		else
			@renderTarget = new THREE.WebGLRenderTarget w , h , o

	setSize: (w,h) ->
		if @renderTarget? then @renderTarget.setSize w , h

	imageToWebGLRenderTarget: ( img ) ->
		mat = new THREE.MeshBasicMaterial map : img
		return @materialToWebGLRenderTarget mat

	materialToWebGLRenderTarget: ( mat ) ->
		@mesh.material = mat
		return @render()

	render: () ->
		if not @renderTarget?
			console.warn '[TextureHelper] No renderTarget yet. Initiating Default RenderTarget... ', this
			return false
		@renderer.render @scene , @camera , @renderTarget
		return @renderTarget.clone()

	getSolidRenderTarget: ( r , g , b ) ->
		solid = @getSolidMaterial r , g , b
		return @materialToWebGLRenderTarget solid

	getSolidMaterial: ( r , g , b ) ->
		solid = new THREE.MeshBasicMaterial()
		solid.color.setRGB r , g , b
		return solid

module.exports = TextureHelper
THREE = require 'three'
$ = require 'jquery'
require('./../vendor/gradientui')($)

class GradientMappingMaterial
	constructor: () ->
		@uniforms =
			tSource : {type: "t" , value: undefined}
			color1  : {type: "v4", value: new THREE.Vector4(0, 0, 0, 0.00)}
			color2  : {type: "v4", value: new THREE.Vector4(0, 0, 0, 0.10)}
			color3  : {type: "v4", value: new THREE.Vector4(1, 1, 1, 0.60)}
			color4  : {type: "v4", value: new THREE.Vector4(1, 1, 1, 0.80)}
			color5  : {type: "v4", value: new THREE.Vector4(1, 1, 1, 1.00)}
			
		@material = new THREE.ShaderMaterial
			uniforms: @uniforms
			vertexShader: require './../shader/standard.vs.glsl'
			fragmentShader: require './../shader/gradient-mapping.fs.glsl'

	setupInterface: (parent) ->
		# Objects
		$ui = $('<div class="controller"></div>')
		$gradientController = $('<div class="gradientui"></div>')
		# Add to DOM Tree
		$ui.append $gradientController
		$(parent).append $ui
		# Add to property
		@$gradientController = $gradientController
		# Gradient UI
		$gradientController
			.gradient 
				values: [
					[0.00, '#033F09'],
					[0.20, '#651584'],
					[0.21, '#a6554d'],
					[0.40, '#35ca51'],
					[0.60, '#FFFFFF']
				]
			.gradient 'setUpdateCallback' , () => 
				@updateUniforms $gradientController.gradient "getValuesRGBS"
		@updateUniforms $gradientController.gradient "getValuesRGBS"

	updateInterface: ( values ) ->
		@$gradientController.gradient 'setGradient' , values

	updateUniforms: (rgbs) ->
		@uniforms["color"+(index+1)].value.fromArray color for color, index in rgbs

module.exports = GradientMappingMaterial
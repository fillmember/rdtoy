THREE = require 'three'

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

module.exports = GradientMappingMaterial
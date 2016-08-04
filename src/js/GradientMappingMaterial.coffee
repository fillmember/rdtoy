require('./../vendor/gradientui')($)

defaultValues = [
					[0.00, '#FFFFFF']
					[0.18, '#CCCCCC']
					[0.24, '#FFFFFF']
					[0.30, '#0000FF']
					[1.00, '#000000']
				]

class GradientMappingMaterial
	constructor: () ->
		@uniforms =
			tSource : {type: "t" , value: undefined}
			color1  : {type: "v4", value: new THREE.Vector4(0,0,0,0)}
			color2  : {type: "v4", value: new THREE.Vector4(0,0,0,0)}
			color3  : {type: "v4", value: new THREE.Vector4(0,0,0,0)}
			color4  : {type: "v4", value: new THREE.Vector4(0,0,0,0)}
			color5  : {type: "v4", value: new THREE.Vector4(0,0,0,0)}
			
		@material = new THREE.ShaderMaterial
			uniforms: @uniforms
			vertexShader: require './../shader/standard.vs.glsl'
			fragmentShader: require './../shader/gradient-mapping.fs.glsl'

	setupInterface: (section) ->
		# Objects
		$gradient = $('<div class="gradientui"></div>')
		# Add to DOM Tree
		section.append UI.item [
			UI.itemHeader UI.spanText 'Display Color'
			UI.col $gradient
		]
		# Gradient UI
		$gradient
			.gradient 
				values: defaultValues
			.gradient 'setUpdateCallback' , () => 
				@updateUniforms $gradient.gradient "getValuesRGBS"
		@updateUniforms $gradient.gradient "getValuesRGBS"
		# Add to property
		@$gradientController = $gradient
		#
		bw_toggle = false 
		#
		section.append UI.btnGroup [
			UI.button
				icon: 'fa-paw'
				name: 'colorful surprise'
				action: => @randomColorScheme()
			UI.button
				icon: 'fa-adjust'
				name: 'black & white'
				action: =>
					b = new THREE.Color(0,0,0)
					w = new THREE.Color(1,1,1)
					if bw_toggle
						values = [ [0.0, b], [0.2, b], [0.4, w], [0.9, w], [1.0, w] ]
					else
						values = [ [0.0, w], [0.2, w], [0.4, b], [0.9, b], [1.0, b] ]
					@animateTo values
					bw_toggle = not bw_toggle
		]

	randomColorScheme: () ->
		random = Math.random
		randomColor = ->
			c = new THREE.Color random() , random() , random()
			return c
		numAround = ( v , range = 0.1 ) ->
			r = v + ( random() * 2 - 1 ) * range
			r = Math.max 0 , r
			r = Math.min 1 , r
			return r
		targetValues = [
			[ numAround(0.0) , randomColor() ]
			[ numAround(0.1) , randomColor() ]
			[ numAround(0.2) , randomColor() ]
			[ numAround(0.4) , randomColor() ]
			[ numAround(0.8) , randomColor() ]
		]
		@animateTo targetValues

	animateTo: ( values ) ->
		d = 0.5
		for i in [0..4]
			vars =
				x: values[i][1].r
				y: values[i][1].g
				z: values[i][1].b
				w: values[i][0]
			if i is 0
				vars.onComplete = vars.onUpdate = => @updateInterface()
			TweenMax.to @uniforms['color'+(i+1)].value , d , vars

	updateColor: ( values ) ->
		@updateInterface values
		@updateUniforms @$gradientController.gradient "getValuesRGBS"

	updateInterface: ( values ) ->
		if not values?
			values = []
			tc = new THREE.Color(0,0,0)
			for i in [1..5]
				c = @uniforms['color'+i].value
				tc.setRGB( c.x , c.y , c.z )
				values.push [c.w , '#'+tc.getHexString()]
		@$gradientController.gradient 'setValues' , values

	updateUniforms: (rgbs) ->
		@uniforms["color"+(index+1)].value.fromArray color for color, index in rgbs

module.exports = GradientMappingMaterial
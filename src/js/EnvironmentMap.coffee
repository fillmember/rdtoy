THREE = require 'three'
$ = require 'jquery'

DrawPad = require './DrawPad'
UI = require './utils/InterfaceUtils'
stackBlur = require './../vendor/StackBlur'

class EnvironmentMap extends DrawPad
	constructor: (options)->
		super options

		@fill 0.31 , 0.6 , 0.1
		@brushColor = new THREE.Color 0.31 , 0.6 , 0.1

		@texture = new THREE.Texture @canvas
		@texture.magFilter = THREE.NearestFilter
		@texture.minFilter = THREE.NearestFilter
		@texture.needsUpdate = true

		@events.on "drawing" , => @updateTexture()

		@video = false
		@videoTag = options.video or document.createElement('video')
		@videoTag.ontimeupdate = => @updateTexture()

	updateTexture: -> @texture.needsUpdate = true

	switchToVideoTexture: () ->
		@video = true
		@texture.image = @videoTag
		@updateTexture()

		$(@canvas).toggleClass 'hide' , true
		$(@videoTag).toggleClass 'hide' , false

	switchToCanvasTexture: () ->
		@video = false
		@videoTag.src = null
		@texture.image = @canvas
		@updateTexture()
		$(@canvas).toggleClass 'hide' , false
		$(@videoTag).toggleClass 'hide' , true

	setupInterface: ( section , root ) ->
		sliders =
			feed: UI.slider
				name: 'feed'
				icon: 'fa-plus-circle'
				object: @brushColor
				property: 'r'
				min: 0
				max: 0.8
				step: 0.025
			kill: UI.slider
				name: 'kill'
				icon: 'fa-bolt'
				object: @brushColor
				property: 'g'
				min: 0
				max: 0.8
				step: 0.025
			step: UI.slider
				name: 'step'
				icon: 'fa-search'
				object: @brushColor
				property: 'b'
				min: 0.025
				max: 1
				step: 0.025
				display: (v) -> v + 'x'
		presets = require './SimulationPresets'
		options = []
		options.push [o.name,i] for o, i in presets
		section.append UI.item [
			UI.item UI.col [
				UI.itemHeader [
					UI.icon 'fa-paint-brush fa-fw'
					UI.spanText 'presets'
				]
				UI.select
					name: 'presets'
					options: options
					onChange: (value) ->
						value = parseInt value
						if value >= 0 and value < presets.length
							p = presets[value]
							if p.feed? then sliders.feed.find('input[type=range]').prop('value',p.feed).trigger('change')
							if p.kill? then sliders.kill.find('input[type=range]').prop('value',p.kill).trigger('change')
							if p.step? then sliders.step.find('input[type=range]').prop('value',p.step).trigger('change')
			]
			# UI.item [
			# 	UI.btnGroup [
			# 		UI.button
			# 			name: ''
			# 			icon: 'fa-bolt'
			# 			checkbox: true
			# 			checked: true
			# 			action: (t) => sliders.kill.toggle t
			# 		UI.button
			# 			name: ''
			# 			icon: 'fa-plus-circle'
			# 			checkbox: true
			# 			checked: true
			# 			action: (t) => sliders.feed.toggle t
			# 		UI.button
			# 			name: ''
			# 			icon: 'fa-search'
			# 			checkbox: true
			# 			checked: true
			# 			action: (t) => sliders.step.toggle t
			# 	]
			# ]
			sliders.feed
			sliders.kill
			sliders.step
			UI.slider
				name: 'soft'
				object: @
				property: 'brushSoftness'
				min: 0
				max: 1
				step: 0.01
				onInput: (v) => @brushOpacity = Math.max 0.05 , 1 - 0.9 * @brushSoftness
		]
		section.append UI.btnGroup [
			UI.button
				name: 'fill'
				icon: 'fa-globe'
				action: =>
					@fill @brushColor.r , @brushColor.g , @brushColor.b
					@updateTexture()
			UI.button
				name: 'blur'
				icon: 'fa-cloud'
				action: =>
					stackBlur @context, 0, 0, @width, @height, 10
					@updateTexture()
		]
		section.append UI.item [
			UI.btnGroup [
				UI.button
					icon: 'fa-upload'
					name: 'upload environment map'
					action: =>
						envmap = @
						dialogue = $ '<input type="file">'
						dialogue.prop 'accept' , 'video/*,image/*'
						dialogue.change ->
							files = this.files
							if files and files[0]
								file = files[0]
								ext = file.name.split('.').pop().toLowerCase()
								vids = ['mov','mp4','m4v','flv','webm','ogg']
								pics = ['jpg','jpeg','gif','png','bmp']
								if vids.indexOf(ext) > -1
									# Video Treatment
									fileURL = URL.createObjectURL file
									envmap.videoTag.src = fileURL
									envmap.switchToVideoTexture()
								else if pics.indexOf(ext) > -1
									# Picture Treatment
									reader = new FileReader()
									reader.onload = (e) ->
										envmap.drawData e.target.result , ->
											envmap.switchToCanvasTexture()
									reader.readAsDataURL file
								else
									alert 'unsupported file format'
						dialogue.click()
			]
		]

module.exports = EnvironmentMap
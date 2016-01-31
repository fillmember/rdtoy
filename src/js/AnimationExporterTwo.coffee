EventEmitter = require('events').EventEmitter

UI = require('./utils/InterfaceUtils')

require './../vendor/whammy/whammy.js'
require './../vendor/ccapture/CCapture.js'


MODE =
	ONESHOT       : 'a' #a : one shot
	CONTINUAL     : 'b'
	STARTONEXPORT : 'c' #b : run while exporting
	EXPORTSTEPS   : 'd' #c : export while drawing
MODE_Desc = {}
MODE_Desc[MODE.ONESHOT]       = 'a - one shot'
MODE_Desc[MODE.CONTINUAL]     = 'b - continual'
MODE_Desc[MODE.STARTONEXPORT] = 'c - step while record'
MODE_Desc[MODE.EXPORTSTEPS]   = 'd - record every step'


class AnimationExporterTwo
	constructor: (target)->
		
		# Constants
		@MODE = MODE

		# Properties
		@target = target
		@canvas = target.renderer.domElement
		@capturing = false
		@renderSetting =
			format: 'webm'
			verbose: true
			duration: 60
			from: 0
			mode: MODE.ONESHOT

		window.yee = this

		# Objects
		@events = new EventEmitter()
		@capture = new CCapture
			quality: 1
			format: @renderSetting.format

	setupInterface: (section, root) ->
		# modes
		toMode = (thismode) =>
			if @renderSetting.mode is thismode then return
			@renderSetting.mode = thismode
			@events.emit 'modechange' , @renderSetting.mode
			@events.emit 'ui' , 'mode'
		makeModeBtn = (mode) =>
			checked = mode is @renderSetting.mode
			return UI.button
				icon: false
				name: mode
				group: 'exportModeGroup'
				checkbox: true
				solo: true
				root: section
				checked: checked
				action: => toMode mode
		section.append [
			UI.item [
				UI.display
					icon: 'fa-cog'
					name: 'mode'
					object: @renderSetting
					property: 'mode'
					eventEmitter: @events
					eventName: 'ui'
					display: (v) -> MODE_Desc[v]
				UI.btnGroup (makeModeBtn MODE[n] for n of MODE)
			]
			# render settings
			UI.item [
				UI.slider
					name: 'duration'
					icon: 'fa-clock-o'
					object: @renderSetting
					property: 'duration'
					min: 60
					max: 900
					step: 60
					display: (v) -> v / 60 + ' secs'
					onInput: => @events.emit 'ui' , 'frames'
				UI.display
					icon: 'fa-arrow-right'
					name: 'frames'
					object: @renderSetting
					property: 'duration'
					eventEmitter: @events
					eventName: 'ui'
					display: (v) =>
						p = (v) -> _.padLeft v , 4 , '0'
						from = @renderSetting.from
						"#{p(from)}-#{p(from+v)} (#{v} frames)"
			]
		]
		exporter = this
		downloadImage = (btn,e) ->
			this.href = exporter.getData()
			this.download = exporter.getFilename _.padLeft Math.floor( Math.random() * 999999 ) , 6 , '0'
		handler = (now) =>
			@capture.capture @canvas
		section.append UI.btnGroup [
			UI.button
				icon: 'fa-video-camera'
				name: 'record'
				checkbox: true
				action: (v,btn) =>
					if v is true
						@capture.start()
						@target.events.on 'run' , handler
					else
						@target.events.removeListener 'run' , handler
						@capture.stop()
						@capture.save (url)-> console.log url
			UI.button
				link: true
				icon: 'fa-camera'
				name: 'still image'
				action: downloadImage
		]
		return section



module.exports = AnimationExporterTwo



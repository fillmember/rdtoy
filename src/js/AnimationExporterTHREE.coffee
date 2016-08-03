EventEmitter = require('events').EventEmitter
UI = require('./utils/InterfaceUtils')

MessageType =
	start: 0
	finish: 1
	frame: 2
	video: 3

MODE =
	ONESHOT       : 0 #a : normal
	CONTINUAL     : 1
	STARTONEXPORT : 2 #b : run while exporting
	EXPORTSTEPS   : 3 #c : export while drawing
ModeDescription = {}
ModeDescription[MODE.ONESHOT]       = 'a - normal'
ModeDescription[MODE.CONTINUAL]     = 'b - continual'
ModeDescription[MODE.STARTONEXPORT] = 'c - step while export'
ModeDescription[MODE.EXPORTSTEPS]   = 'd - export every step'

class AnimationExporter
	constructor: ({
		# source
		@canvas
		# file
		@extension = 'png'
		# connection
		@url = 'ws://127.0.0.1:4000'
		fps = 30
	}) ->
		# programming
		@events = new EventEmitter()
		# frame
		@frame = 0
		@frameStep = 1
		# animation frame related
		@msPerFrame = 1000
		@lastFrame = undefined
		@setFPS fps
		# Export Options
		@options =
			duration: 60
			from: 0
			mode: MODE.ONESHOT
		@MODES = MODE

	# Gets
	getData: () -> return @canvas.toDataURL @dataType
	getFilename: (name) -> return [@name,name or @frame,@extension].join('.')

	# Sets
	setFPS: (fps) -> @msPerFrame = 1000 / fps

	renderVideo: (startFrame = 0, endFrame) ->
		@events.emit 'start'
		@recording = true
		@frame = startFrame
		@endFrame = endFrame
		@step()
	
	step: ( ) ->
		if not @recording then return
		@events.emit 'step'
		@frame += 1
		if @frame < @endFrame
			requestAnimationFrame @step.bind(this)
		else
			@events.emit 'finish'
			@recording = false
			@events.emit 'ui'

	setupInterface: (section, root) ->
		## mode
		##
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
					object: @options
					property: 'mode'
					eventEmitter: @events
					eventName: 'ui'
					display: (v) -> ModeDescription[v]
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
		# -----
		exporter = this
		section.append UI.item UI.btnGroup [
			UI.button
				icon: 'fa-truck'
				name: 'export frames'
				action: (btn) =>
					btn.prop 'disabled', true
					from = @options.from
					to = from + @options.duration
					@connect -> exporter.renderVideo from , to
					enable = =>
						btn.prop 'disabled' , false
						@events
							.removeListener 'finish' , enable
							.removeListener 'close' , enable
					@events
						.once 'finish' , enable
						.once 'close' , enable
			UI.button
				icon: 'fa-file-video-o'
				name: 'get video'
				action: (btn) => @connect -> exporter.websocket.send JSON.stringify a: MessageType.video
			UI.button
				link: true
				icon: 'fa-camera'
				name: 'still image'
				action: (btn,e) ->
					this.href = exporter.getData()
					this.download = exporter.getFilename _.padLeft Math.floor( Math.random() * 999999 ) , 6 , '0'
		]
		return section

module.exports = AnimationExporter
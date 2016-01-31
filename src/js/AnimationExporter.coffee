EventEmitter = require('events').EventEmitter
UI = require('./utils/InterfaceUtils')

ServerStatus = 
	NOT_CONNECTED    : 1001
	CONNECTING       : 1002
	WEBSOCKET_OPEN   : 1003
	WEBSOCKET_CLOSED : 1004
	WEBSOCKET_ERROR  : 1005
	SERVER_READY     : 2001
	SERVER_BUSY      : 2002

ServerStatus_Desc = {}
ServerStatus_Desc[ServerStatus.NOT_CONNECTED   ] = "not connected"
ServerStatus_Desc[ServerStatus.CONNECTING      ] = "connecting"
ServerStatus_Desc[ServerStatus.WEBSOCKET_OPEN  ] = "connected"
ServerStatus_Desc[ServerStatus.WEBSOCKET_CLOSED] = "connection closed"
ServerStatus_Desc[ServerStatus.WEBSOCKET_ERROR ] = "connection error"
ServerStatus_Desc[ServerStatus.SERVER_READY    ] = "server ready"
ServerStatus_Desc[ServerStatus.SERVER_BUSY     ] = "server busy..."

MessageType =
	start: 0
	finish: 1
	frame: 2
	video: 3

MODE =
	MODE_ONESHOT       : 0 #a : normal
	MODE_CONTINUAL     : 1
	MODE_STARTONEXPORT : 2 #b : run while exporting
	MODE_EXPORTSTEPS   : 3 #c : export while drawing
MODE_Desc = {}
MODE_Desc[MODE.MODE_ONESHOT]       = 'a - normal'
MODE_Desc[MODE.MODE_CONTINUAL]     = 'b - continual'
MODE_Desc[MODE.MODE_STARTONEXPORT] = 'c - step while export'
MODE_Desc[MODE.MODE_EXPORTSTEPS]   = 'd - export every step'

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
		# file
		@name = 'output'
		@dataType = "image/#{@extension}"
		# frame
		@frame = 0
		@frameStep = 1
		# connection
		@protocols =
			A : 'A'
		@websocket
		@serverStatus = ServerStatus.NOT_CONNECTED
		@serverInfo =
			framesInBuffer : 0
		# animation frame related
		@msPerFrame = 33.3
		@lastFrame = undefined
		@setFPS fps
		# Export Options
		@options =
			duration: 60
			from: 0
			mode: MODE.MODE_ONESHOT
		@MODES = MODE

	# Gets
	getData: () -> return @canvas.toDataURL @dataType
	getFilename: (name) -> return [@name,name or @frame,@extension].join('.')

	# Sets
	setFPS: (fps) -> @msPerFrame = 1000 / fps

	# WebSocket
	connect: (callback) ->
		if @websocket? and @websocket.readyState is 1
			# already connected, directly callback
			return callback()
		@serverStatus = ServerStatus.CONNECTING
		@events.emit "connect"
		@websocket = new WebSocket( @url, @protocols.A )
		@websocket.onopen    = (e) =>
			@serverStatus = ServerStatus.WEBSOCKET_OPEN
			@events.emit 'open'
			@events.emit 'ui'
			if callback? then return callback()
		@websocket.onerror   = (e) =>
			@serverStatus = ServerStatus.WEBSOCKET_ERROR
			@events.emit 'error' , e
			@events.emit 'ui'
		@websocket.onclose   = (e) =>
			@serverStatus = ServerStatus.WEBSOCKET_CLOSED
			@events.emit 'close' , e
			@events.emit 'ui'
		@websocket.onmessage = @onMessage.bind this

	onMessage: (e) ->
		if e.data is 'busy'
			@serverStatus = ServerStatus.SERVER_BUSY
		else if e.data is 'ready'
			@serverStatus = ServerStatus.SERVER_READY
			@events.emit 'serverready'
		else if e.data.indexOf('framecount-') != -1
			n = parseInt e.data.split('-')[1]
			@serverInfo.framesInBuffer = parseInt n
			if @options.mode > 0
				@options.from = n
				@events.emit 'ui'
			# @events.emit 'ui', 'response' , "frames in buffer: #{n}"
		else if e.data.indexOf('video:') != -1
			url = e.data.split(':')[1]
			@events.emit 'ui', 'response' , 'video!'
		@events.emit 'message' , e.data
		# @events.emit 'ui' , 'response' , e.data

	renderVideo: (startFrame = 0, endFrame) ->
		@events.once 'serverready' , =>
			@events.emit 'start'
			@recording = true
			@frame = startFrame
			@endFrame = endFrame
			@step()
		@websocket.send JSON.stringify
			a: MessageType.start
			f0: startFrame
	
	step: ( ) ->
		if not @recording then return
		@events.emit 'step'
		@websocket.send JSON.stringify
			a: MessageType.frame
			n: @getFilename()
			d: @getData()
		@frame += 1
		if @frame < @endFrame
			requestAnimationFrame @step.bind(this)
		else
			@events.emit 'finish'
			@recording = false
			@websocket.send JSON.stringify
				a: MessageType.finish
			# if @options.mode > 0
			# 	@options.from = @endFrame
			@events.emit 'ui'

	setupInterface: (section, root) ->
		## mode
		##
		modeUpdate = (thismode) =>
			if @options.mode is thismode then return
			@options.mode = thismode
			@events.emit 'modechange' , @options.mode
			@events.emit 'ui' , 'mode'
		section.append [
			UI.item [
				UI.display
					icon: 'fa-cog'
					name: 'mode'
					object: @options
					property: 'mode'
					eventEmitter: @events
					eventName: 'ui'
					display: (v) -> MODE_Desc[v]
				UI.btnGroup [
					UI.button
						icon: false
						name: 'a'
						group: 'exportModeGroup'
						checkbox: true
						solo: true
						root: section
						action: => modeUpdate MODE.MODE_ONESHOT
						checked: true
					UI.button
						icon: false
						name: 'b'
						group: 'exportModeGroup'
						checkbox: true
						solo: true
						root: section
						action: => modeUpdate MODE.MODE_CONTINUAL
					UI.button
						icon: false
						name: 'c'
						group: 'exportModeGroup'
						checkbox: true
						solo: true
						root: section
						action: => modeUpdate MODE.MODE_STARTONEXPORT
					UI.button
						icon: false
						name: 'd'
						group: 'exportModeGroup'
						checkbox: true
						solo: true
						root: section
						action: => modeUpdate MODE.MODE_EXPORTSTEPS
				]
			]
			UI.item [
				UI.slider
					name: 'duration'
					icon: 'fa-clock-o'
					object: @options
					property: 'duration'
					min: 60
					max: 900
					step: 60
					display: (v) -> v / 60 + ' secs'
					onInput: => @events.emit 'ui' , 'frames'
				UI.display
					icon: 'fa-arrow-right'
					name: 'frames'
					object: @options
					property: 'duration'
					eventEmitter: @events
					eventName: 'ui'
					display: (v) =>
						from = @options.from
						to   = @options.from + v
						from = _.padLeft from , 4 , '0'
						to   = _.padLeft to   , 4 , '0'
						"#{v} frames [#{from}-#{to}]"
			]
		]
		# -----
		exporter = this
		section.append [
			UI.item [
				UI.btnGroup [
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
				UI.display
					icon: 'fa-binoculars'
					name: 'server'
					object: @
					property: 'serverStatus'
					eventEmitter: @events
					eventName: 'ui'
					display: (v) ->
						desc = ServerStatus_Desc[v]
						if desc
							return desc
						else
							return v
				UI.display
					icon: 'fa-commenting-o'
					name: 'response'
					eventEmitter: @events
					eventName: 'ui'
			]
		]
		return section

module.exports = AnimationExporter
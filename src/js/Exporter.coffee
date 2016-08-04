require './../vendor/whammy/whammy.js'
require './../vendor/ccapture/CCapture.js'
EventEmitter = require('events').EventEmitter
UI = require './utils/InterfaceUtils'

class Exporter
	constructor: (args) ->
		{simulator,canvas,UIRoot} = args
		#
		@events = new EventEmitter()
		@data = []
		@status = 
			capturing : no
		@settings =
			captureWhileDrawing : false
		@UI = {}
		@canvas = canvas
		@simulator = simulator
		#
		@init args
	init: ({UIRoot}) ->
		@simulator.events.on 'run' , =>
			if @status.capturing and @simulator.running then @add()
		@simulator.events.on 'draw' , =>
			if not @status.capturing and @settings.captureWhileDrawing then @add()
		@initUI UIRoot
	initUI: (root) ->
		root.append UI.section
			icon: 'fa-truck'
			name: 'render'
			child: [
				UI.item [
					UI.btnGroup [
						UI.button
							link: true
							icon: 'fa-file-image-o'
							name: 'save current frame'
							action: (btn) =>
								timestamp = String( Date.now() ).substr( -6 , 6 )
								filename = "rdplay-#{timestamp}"
								btn.prop 'download' , "#{filename}.png"
								btn.prop 'href' , @canvas.toDataURL 'image/png'
					]
				]
				UI.item [
					@UI.bufferDisplay = UI.display
						icon: 'fa-cloud'
						name: 'buffer'
						object: @data
						property: 'length'
						eventEmitter: @events
						eventName: 'ui'
						display: (v)->v+' frame'+(if v > 1 then 's' else '')+' in buffer'
					UI.btnGroup [
						@UI.captureButton = UI.button
							icon: 'fa-video-camera'
							name: 'capture'
							checkbox: true
							action: (v)=>
								@status.capturing = v
								if @status.capturing
									@toggleRecordState 'captureButton' , yes
									@toggleRecordState 'bufferDisplay' , yes
									@simulator.setRunning true
								else
									@toggleRecordState 'captureButton' , no
									@toggleRecordState 'bufferDisplay' , no
									@simulator.setRunning false
									@update()
						@UI.getWebMButton = UI.button
							icon: 'fa-share-square-o'
							name: 'save webm'
							action: =>
								blob = Whammy.fromImageArray @data , 30 , false
								url = URL.createObjectURL blob
								window.open url
						@UI.clearBufferButton = UI.button
							icon: 'fa-trash-o'
							name: 'clear buffer'
							action: =>
								@data.length = 0
								@update()
					]
				]
				UI.item [
					UI.itemHeader [
						UI.icon 'fa-link'
						UI.spanText 'auto capture when...'
					]
					UI.btnGroup [
						UI.button
							icon: 'fa-paint-brush'
							name: 'drawing'
							checkbox: true
							checked: @settings.captureWhileDrawing
							group: 'captureConditionGroup'
							root: root
							action: (v) => @settings.captureWhileDrawing = v
					]
				]
			]
	add: ->
		@data.push @canvas.toDataURL 'image/webp'
		@update()
	update: ->
		@events.emit 'ui'
	toggleUI: (dom,bool) -> @UI[dom].prop 'disabled' , !bool
	toggleRecordState: (dom,bool) -> @UI[dom].toggleClass 'pulsing red' , bool


module.exports = Exporter
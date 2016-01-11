gulp   = require 'gulp'
gutil  = require 'gulp-util'

fs = require 'fs-extra'
_ = require 'lodash'

require './../src/vendor/Math.uuid.js'

gulp.task 'server', ->
	# Requires
	express = require('express')
	app = express()
	expressWs = require('express-ws')(app)
	exec = require('child_process').exec
	# Constants
	MessageType =
		START: 0
		FINISH: 1
		FRAME: 2
		VIDEO: 3
	# Frame
	from = 0
	frames = []
	# I/O
	Folders =
		temp: './temp/'
		dist: './dist/videos/'
	ext = 'png'
	# Server Logic
	app.ws '/' , (ws,req) ->
		ws.on 'message' , (msg) ->
			obj = JSON.parse msg
			switch obj.a
				when MessageType.START
					from = obj.f0 or 0
					ws.send 'ready'
				when MessageType.FINISH
					ws.send 'busy'
					ws.send 'framecount-'+( frames.length + from )
					framesToFiles frames , => frames = []
					ws.send 'ready'
				when MessageType.FRAME
					frames.push obj.d
				when MessageType.VIDEO
					ws.send 'busy'
					makeVideo (url) ->
						ws.send "video:#{url}"
						fs.emptyDirSync Folders.temp
						from = 0
						ws.send 'framecount-0'
						ws.send 'ready'
				else
					ws.send 'unknownrequest'
	# init Server
	server = app.listen 4000 , -> gutil.log "Server Listening at port #{server.address().port}"

	# Functions
	run = (command,callback) ->
		gutil.log gutil.colors.blue('run:'), command, '\n'
		proc = exec command , (error) ->
			if error?
				gutil.log gutil.colors.bold.red('exec error: ') + error
		proc.stderr.on 'data' , gutil.log
		proc.stdout.on 'data' , gutil.log
		proc.stdout.on  'end' , callback.bind(this)

	getName = (t) ->
		if not t? then t = new Date()
		return "output_#{Math.uuid(4)}_" + [
			t.getFullYear()
			_.padLeft t.getMonth(), '0'
			_.padLeft t.getDate(),  '0'
		].join('-') + '_' + [
			_.padLeft t.getHours(),   '0'
			_.padLeft t.getMinutes(), '0'
			_.padLeft t.getSeconds(), '0'
		].join('.')

	makeVideo = (callback)->
		output = Folders.dist + getName() + '.mp4'
		command = [
			'ffmpeg'
			'-framerate 60'
			"-i #{Folders.temp}temp.%4d.#{ext}"
			'-pix_fmt yuv420p'
			'-c:v libx264'
			'-profile:v main -level 3.1'
			output
		].join ' '
		run command , -> if callback? then callback output

	framesToFiles = (frames, callback) ->
		ext = getType(frames[0]) or 'png'
		frames.forEach (frame,i) ->
			n = _.padLeft ( from + i ), 4, '0'
			fs.writeFile "#{Folders.temp}temp.#{n}.#{ext}", toBuffer frame
		if callback? then callback()

	getType = (data) ->
		match = data.match /^data:image\/([A-Za-z-+]+);/
		return if match? then match[1] else undefined

	toBuffer = (data) ->
		match = data.match /^data:[A-Za-z-+\/]+;base64,(.+)$/
		return if match? then new Buffer match[1] , 'base64' else undefined
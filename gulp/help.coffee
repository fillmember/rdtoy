gulp  = require 'gulp'
gutil = require 'gulp-util'
yargs = require 'yargs'

gulp.task 'help' , (cb) ->
	header = gutil.colors.bold
	title = gutil.colors.bgBlack.white
	text = [
		title ' TENPLATE '
		header 'usage: '
		'gulp [watch|build|clean] [options]'
		''
		header 'while gulp clean: '
		'--all    clean all'
		''
		header 'while gulp build/watch: '
		'--dev              set __DEV__ to true'
		'--nodev            set __DEV__ to false'
		''
	].join '\n'
	console.log text
	return cb()
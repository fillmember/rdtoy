gulp = require 'gulp'
del  = require 'del'
yargs = require 'yargs'

gulp.task 'clean', -> 
    argv = yargs.argv
    all = argv.all
    if all
        del 'dist/'
    else
        del 'dist/js/*.js'
        del 'dist/css/*.css'
        del 'dist/*.html'
        del 'dist/js/*.js.map'
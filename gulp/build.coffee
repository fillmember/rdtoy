gulp   = require 'gulp'
gutil  = require 'gulp-util'
run    = require 'run-sequence'
jade   = require 'gulp-jade'
stylus = require "gulp-stylus"

webpack     = require "webpack"
browserSync = require("browser-sync").get("A")


gulp.task 'build', (cb) ->
    run(
        'clean'
        'build-files'
        'webpack:build'
        cb)

gulp.task 'build-files', (cb) ->
    run(
        [
            'build-css'
            'build-stylus'
            'build-jade'
            'build-assets'
        ],
        cb
    )

gulp.task 'build-stylus', ->
    gulp.src ['src/stylus/**/*.styl']
        .pipe stylus()
        .pipe gulp.dest('dist/css')
        .pipe browserSync.stream()

gulp.task 'build-css', ->
    gulp.src ['src/css/**/*.css']
        .pipe gulp.dest('dist/css')
        .pipe browserSync.stream()

gulp.task 'build-assets', (cb) ->
    gulp
        .src ['src/assets/**/*']
        .pipe gulp.dest('dist/assets')
        .pipe browserSync.stream()

gulp.task 'build-jade', ->
    gulp.src ['./src/jade/**/*.jade']
        .pipe jade pretty: true
        .pipe gulp.dest('./dist/')
        .pipe browserSync.stream()

gulp.task 'webpack:build', (cb) ->
    webpackConfig = require("./../webpack.config.js")
    # Transform config for Build task
    webpackConfig.plugins.push new webpack.optimize.UglifyJsPlugin sourceMap:false, compress: {warnings: false}
    # webpack
    webpack webpackConfig, (err, stats) ->
        if err then throw new gutil.PluginError "webpack:build" , err
        gutil.beep()
        gutil.log "[webpack:build]", stats.toString colors: true
        cb()
gulp   = require 'gulp'
gutil  = require 'gulp-util'
run    = require 'run-sequence'
jade   = require 'gulp-jade'
stylus = require "gulp-stylus"

webpack     = require "webpack"
browserSync = require("browser-sync").get("A")


gulp.task 'watch', ->
    run(
        'clean'
        'build-files'
        'browserSync'
        'webpack:watch'
    )
    gulp.watch './src/stylus/**/*.styl', ['build-stylus']
    gulp.watch './src/css/**/*.css'    , ['build-css']
    gulp.watch './src/jade/**/*.jade'  , ['build-jade']
    gulp.watch './src/assets/**/*'  , ['build-assets']

gulp.task 'webpack:watch', (cb) ->
    webpackConfig = require("./../webpack.config.js")
    # Transform config for Watch task
    webpackConfig.debug = true
    webpackConfig.devtool = "source-map"
    webpackConfig.watch = true
    webpackConfig.devServer = {
      aggregateTimeout: 300,
      quiet: false,
      noInfo: false,
      lazy: true,
      port: 3000
    }
    # webpack
    webpack webpackConfig, (err, stats) ->
        if err then throw new gutil.PluginError "webpack:watch" , err
        gutil.log "[webpack:watch]", stats.toString colors: true
        browserSync.reload()
gulp = require "gulp"
browserSync = require("browser-sync").create("A")


gulp.task 'browserSync', (cb) ->
    browserSync.init {
        server: "./dist",
        port: 3000
    }
    cb()
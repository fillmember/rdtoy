Tenplate
=======================================

I want a simple foundation for my experiments. I want it to be minimal and welcome all kinds of syntax, pre-processors, whatever you want to use. 

Tools Used:

- Gulp
- BrowserSync
- Webpack

And these are ready to use!

- Stylus
- Jade
- Coffeescript
- Babel ES2015

## Features & Structures

one liner -- Takes things in src and put them into dist. 

### Folders:

- assets : for images and other static content. Will be copied to `dist/` (you can extend this process in `gulp/build.coffee`)
- jade   : each `.jade` file will become a html file in `dist/`
- stylus : each `.styl` file will become a css file in `dist/css/`
- css    : each `.css` file in here will be copied to `dist/css/` for `@import` use
- js     : webpack is in charge here. entry point is `main.js`

### Code:

Webpack inject a boolean variable `__DEV__` into files. The value will be `true` in watch mode or you specify `--dev` flag in build mode. You can modify this logic in `webpack.config.js`, in the part of plugins. `--nodev` can be use to do the otherwise. 

### Gulp:

`gulp` for help, and start watch.
`gulp watch` for watch in `dist/`  
`gulp build` for build to `dist/`  
`gulp clean` for clean `dist/`, now it only delete documents

## To Expand

You can put in more processes in build-assets, build-css tasks (in `gulp/build.coffee`). Remember to modify watch task (`gulp/watch.coffee`) accordingly. 

To configure webpack, check webpack.config.js for basic configurations such as entry point and output. in `gulp/build.coffee` and `gulp/watch.coffee`, there's also some modification to the config file before it is passed to start webpack. 

## Footer

Feel free to open issues, and/or make pull requests. I want to make this more solid. There definitely can be more improvements on the browserSync-webpack-watch part. 
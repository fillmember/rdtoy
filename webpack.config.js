var path = require("path");
var webpack = require("webpack");
var argv = require("yargs").argv

var config = {

  // This is the main file that should include all other JS files
  entry: {
    Main: "./src/js/Main.coffee"
  },
  output: {
    path: path.join(__dirname, "dist", "js"),
    filename: "[name].js",
    chunkFilename: "[chunkhash].js"
  },
  resolve: { extensions: ['', '.js', '.json', '.coffee', '.jade'] },
  module: {

    loaders: [

      // STYLE
      { test: /\.css/, loader: "style-loader!css-loader" },
      { test: /\.jade/, loader: "jade-loader" },
      { test: /\.styl/, loader: "style-loader!css-loader!stylus-loader" },

      // ASSET
      { test: /\.gif/, loader: "url-loader?limit=10000&minetype=image/gif" },
      { test: /\.jpg/, loader: "url-loader?limit=10000&minetype=image/jpg" },
      { test: /\.png/, loader: "url-loader?limit=10000&minetype=image/png" },
      
      // CODE
      { test: /\.js$/, exclude: /(node_modules|vendor)/, loader: "babel-loader", query: {presets: ['es2015']}},
      { test: /\.coffee$/, loader: "coffee-loader" },
      { test: /\.glsl$/, loader: "shader-loader"}

    ],

    noParse: /\.min\.js/

  },
  plugins: [

    new webpack.DefinePlugin({

      __DEV__: JSON.stringify(JSON.parse( argv.dev || (!argv.nodev && argv._[0] == 'watch') ) )

    }),

  ]

};

module.exports = config
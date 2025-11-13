const path = require('path');
const CopyWebpackPlugin = require('copy-webpack-plugin');

module.exports = {
  mode: 'development',
  devtool: 'source-map',

  entry: {
    'background/service-worker': './src/background/service-worker.js',
    'content/content': './src/content/content.js',
    'popup/popup': './src/popup/popup.js'
  },

  output: {
    path: path.resolve(__dirname, 'dist'),
    filename: '[name].js'
  },

  plugins: [
    new CopyWebpackPlugin({
      patterns: [
        { from: 'manifest.json', to: 'manifest.json' },
        { from: 'src/popup/popup.html', to: 'src/popup/popup.html' },
        { from: 'src/popup/popup.css', to: 'src/popup/popup.css' },
        { from: 'src/utils', to: 'src/utils' },
        { from: 'icons', to: 'icons' }
      ]
    })
  ],

  resolve: {
    extensions: ['.js']
  },

  module: {
    rules: [
      {
        test: /\.js$/,
        exclude: /node_modules/,
        use: {
          loader: 'babel-loader',
          options: {
            presets: ['@babel/preset-env']
          }
        }
      }
    ]
  }
};

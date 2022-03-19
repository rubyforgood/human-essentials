const JSLoader = {
  test: /\.m?js$/i,
  exclude: /node_modules/,
  use: {
    loader: 'babel-loader',
    options: {
      presets: ['@babel/preset-env']
    }
  }
};

module.exports = {
  JSLoader: JSLoader
}
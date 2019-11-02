process.env.NODE_ENV = process.env.NODE_ENV || 'development'

const environment = require('./environment')

// Workaround Sinon+Webpack issues as documented at https://gist.github.com/rrgayhart/cf5dcefdf3975598f491
const sinonLoader = {
  test: /sinon\.js$/, loader: "imports-loader?define=>false,require=>false"
}

environment.loaders.append('sinon', sinonLoader)

module.exports = environment.toWebpackConfig()

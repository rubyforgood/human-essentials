process.env.NODE_ENV = process.env.NODE_ENV || 'development'

const environment = require('./environment')
const chokidar = require('chokidar')

environment.config.devServer.before = (app, server) => {
  chokidar.watch([
    'config/locales/*.yml',
    'app/views/**/*.erb'
  ]).on('change', () => server.sockWrite(server.sockets, 'content-changed'))
}

module.exports = environment.toWebpackConfig()

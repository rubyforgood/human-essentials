const { environment } = require('@rails/webpacker')
const { JSLoader } = require('./loaders');

environment.loaders.append('js', JSLoader);

module.exports = environment

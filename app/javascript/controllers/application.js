import { Application } from "@hotwired/stimulus"
//import { definitionsFromContext } from "@hotwired/stimulus-webpack-helpers"

const application = Application.start()
window.Stimulus = application;

//const context = require.context("/", true, /\.js$/)
//Stimulus.load(definitionsFromContext(context))

// Configure Stimulus development experience
application.debug = false
window.Stimulus   = application

export { application }

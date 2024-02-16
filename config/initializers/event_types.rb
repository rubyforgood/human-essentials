# load all event types so we can use it in e.g. drop-downs.

Rails.application.reloader.to_prepare do
  Dir["#{Rails.root}/app/events/*_event.rb"].each { |f| require f }
end

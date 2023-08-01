require "webmock/rspec"
allowed_sites = [
  "https://chromedriver.storage.googleapis.com",
  "https://github.com/mozilla/geckodriver/releases",
  "https://selenium-release.storage.googleapis.com"
]

allowed_sites << ENV["APP_HOST"] if ENV["APP_HOST"]
allowed_sites << ENV["SELENIUM_HOST"] if ENV["SELENIUM_HOST"]
allowed_sites << `hostname`.strip if ENV["DOCKER"]

WebMock.disable_net_connect!(allow_localhost: true, allow: allowed_sites, net_http_connect_on_start: true)

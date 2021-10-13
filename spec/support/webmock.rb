require "webmock/rspec"
allowed_sites = [
  "https://chromedriver.storage.googleapis.com",
  "https://github.com/mozilla/geckodriver/releases",
  "https://selenium-release.storage.googleapis.com"
]
WebMock.disable_net_connect!(allow_localhost: true, allow: allowed_sites, net_http_connect_on_start: true)

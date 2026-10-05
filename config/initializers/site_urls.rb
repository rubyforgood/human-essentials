# Human Essentials is reachable on several domains (humanessentials.app,
# humanessentialsapp.com, humanessentialsapp.org) because some networks block
# the `.app` TLD. Links rendered during a request are generated from the host
# the visitor actually arrived on, so nothing here is needed for those.
#
# These settings cover the handful of places where we deliberately link to a
# *different* deployment than the one serving the page -- the staging banner
# pointing people at the live site, and the account request email pointing at
# the demo site. Override them per-deployment if the canonical domain changes.
Rails.application.config.x.site_urls.production = ENV.fetch("PRODUCTION_URL", "https://humanessentials.app")
Rails.application.config.x.site_urls.demo = ENV.fetch("DEMO_URL", "https://staging.humanessentials.app")

# Human Essentials is reachable on several domains (humanessentials.app,
# humanessentialsapp.com, humanessentialsapp.org) because some networks block
# the `.app` TLD. Links rendered during a request are generated from the host
# the visitor actually arrived on, so nothing here is needed for those.
#
# These settings cover the handful of places where we deliberately link to a
# *different* deployment than the one serving the page -- the staging banner
# pointing people at the live site, and the account request email pointing at
# the demo site. Override them per-deployment if the canonical domain changes.
#
# `.presence`, not `ENV.fetch`: .env.example lists both with no value, and bin/setup copies it to
# .env, so a fresh checkout sets them to "" -- which `fetch` takes as a value. URI.join("", path)
# then raises, and the staging page and its spec failed on every machine set up that way.
Rails.application.config.x.site_urls.production = ENV["PRODUCTION_URL"].presence || "https://humanessentials.app"
Rails.application.config.x.site_urls.demo = ENV["DEMO_URL"].presence || "https://staging.humanessentials.app"

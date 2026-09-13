# Builds links to a *different* Human Essentials deployment than the one
# currently serving the request. Anything pointing at the current deployment
# should use ordinary route helpers instead, so it follows whichever domain the
# visitor arrived on. See config/initializers/site_urls.rb.
module SiteUrlsHelper
  def production_url(path = "/")
    site_url(site_urls.production, path)
  end

  def demo_url(path = "/")
    site_url(site_urls.demo, path)
  end

  def production_host
    URI.parse(site_urls.production).host
  end

  private

  def site_urls
    Rails.application.config.x.site_urls
  end

  def site_url(base, path)
    URI.join(base, path).to_s
  end
end

# Encapsulates methods that need some business logic
module PartnersHelper
  def documentation_url(path)
    # NOTE(chaserx): add to .env with http://localhost:3001 or https://partnerbase.org
    uri = URI(ENV['PARTNER_BASE_URL'] || "partners.test")
    uri.path = path
    uri.to_s
  end
end

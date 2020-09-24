# Encapsulates methods that need some business logic
module PartnersHelper
  def documentation_url(path)
    # NOTE(chaserx): add to .env with http://localhost:3001 or https://partnerbase.org
    uri = URI(ENV['PARTNER_BASE_URL'] || "partners.test")
    uri.path = path
    uri.to_s
  end

  def show_header_column_class(partner, additional_classes: "")
    if partner.quota.present?
      "col-sm-3 col-3 #{additional_classes}"
    else
      "col-sm-4 col-4 #{additional_classes}"
    end
  end
end

module DiaperPartnerClient
  def self.post(path, attributes)
    diaper_partner_url = ENV["DIAPER_PARTNER_URL"]
    return if diaper_partner_url.blank?

    uri = URI(diaper_partner_url + path)
    request = Net::HTTP::Post.new uri
    request.set_form_data attributes

    Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request ApiAuth.sign!(request, "diaperbase", ENV["DIAPER_PARTNER_SECRET_KEY"])
    end
  end
end

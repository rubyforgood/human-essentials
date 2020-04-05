# Establishes some methods that are used to communicate with the Partner app.
# The Diaper and Partner apps must communicate as if by magic, over a bi-directional
# API.
module PartnerFormClient
  def self.post(attributes)
    uri = URI(ENV["PARTNER_FORM_URL"])
    req = Net::HTTP::Post.new(uri, "Content-Type" => "application/json")
    req.body = partner_form_json(attributes)
    req["Content-Type"] = "application/json"
    req["X-Api-Key"] = ENV["PARTNER_KEY"]

    response = https(uri).request(req)

    response.body
  end

  def self.https(uri)
    Net::HTTP.new(uri.host, uri.port).tap do |http|
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
  end

  def self.partner_form_json(attributes)
    { partner_form:
          { diaper_bank_id: attributes["id"],
            sections: attributes["partner_form_fields"] } }.to_json
  end
end

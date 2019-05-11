# Establishes some methods that are used to communicate with the Partner app.
# The Diaper and Partner apps must communicate as if by magic, over a bi-directional
# API.
module DiaperPartnerClient
  def self.post(attributes)
    partner = { partner:
      { diaper_bank_id: attributes["organization_id"],
        diaper_partner_id: attributes["id"],
        email: attributes["email"] } }

    uri = URI(ENV["PARTNER_REGISTER_URL"])
    req = Net::HTTP::Post.new(uri, "Content-Type" => "application/json")
    req.body = partner.to_json
    req["Content-Type"] = "application/json"
    req["X-Api-Key"] = ENV["PARTNER_KEY"]

    response = https(uri).request(req)

    response.body
  end

  def self.get(attributes)
    id = attributes[:id]
    uri = URI(ENV["PARTNER_REGISTER_URL"] + "/#{id}")
    req = Net::HTTP::Get.new(uri, "Content-Type" => "application/json")

    req["Content-Type"] = "application/json"
    req["X-Api-Key"] = ENV["PARTNER_KEY"]

    response = https(uri).request(req)
    response.body
  end

  def self.put(attributes)
    partner = { partner:
                    {
                      diaper_partner_id: attributes["id"]
                    } }

    uri = URI(ENV["PARTNER_REGISTER_URL"] + "/#{attributes["id"]}")
    req = Net::HTTP::Put.new(uri, "Content-Type" => "application/json")
    req.body = partner.to_json
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
end

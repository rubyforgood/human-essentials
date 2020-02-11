# Establishes some methods that are used to communicate with the Partner app.
# The Diaper and Partner apps must communicate as if by magic, over a bi-directional
# API.
module DiaperPartnerClient
  def self.post(attributes, invitation_message)
    uri = URI(ENV["PARTNER_REGISTER_URL"])
    req = Net::HTTP::Post.new(uri, "Content-Type" => "application/json")
    req.body = partner_json(attributes, invitation_message)
    req["Content-Type"] = "application/json"
    req["X-Api-Key"] = ENV["PARTNER_KEY"]

    response = https(uri).request(req)

    response.body
  end

  def self.add(attributes, invitation_message)
    uri = URI(ENV["PARTNER_ADD_URL"])
    req = Net::HTTP::Post.new(uri, "Content-Type" => "application/json")
    req.body = partner_json(attributes, invitation_message)
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
                      diaper_partner_id: attributes[:partner_id],
                      status: attributes[:status]
                    } }

    uri = URI(ENV["PARTNER_REGISTER_URL"] + "/#{attributes[:partner_id]}")
    req = Net::HTTP::Put.new(uri, "Content-Type" => "application/json")
    req.body = partner.to_json
    req["Content-Type"] = "application/json"
    req["X-Api-Key"] = ENV["PARTNER_KEY"]

    response = https(uri).request(req)

    # NOTE(chaserx): after some research it appears that we don't actually
    #  use the body of the response anywhere. I am diverting from the pattern
    #  of repsonses here so that we can use the response status to trap errors
    #  with a check on the response being a Net::HTTPSuccess type.
    response
  end

  def self.https(uri)
    Net::HTTP.new(uri.host, uri.port).tap do |http|
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
  end

  def self.partner_json(attributes, invitation_message)
    { partner:
          { diaper_bank_id: attributes["organization_id"],
            diaper_partner_id: attributes["id"],
            invitation_text: invitation_message,
            email: attributes["email"] } }.to_json
  end
end

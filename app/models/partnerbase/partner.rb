module Partnerbase
  class Partner < OpenStruct
    def self.find(id)
      partnerbase_response = DiaperPartnerClient.get({ id: id })
      parsed_response = parse_response(partnerbase_response)
      new(parsed_response) if parsed_response
    end

    def self.parse_response(response)
      JSON.parse(response.to_s).with_indifferent_access
    rescue JSON::ParserError
    end
  end
end

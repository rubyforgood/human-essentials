module Partnerbase
  class Partner < OpenStruct
    def self.find(id)
      partnerbase_response = DiaperPartnerClient.get({ id: id })
      parsed_response = parse_response(partnerbase_response)
      new(parsed_response) if parsed_response
    end

    private

    def self.parse_response(response)
      begin
        JSON.parse(response).with_indifferent_access
      rescue JSON::ParserError
      end
    end
  end
end

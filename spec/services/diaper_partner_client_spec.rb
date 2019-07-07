require 'spec_helper'
require_relative '../support/env_helper'

RSpec.describe DiaperPartnerClient, type: :service do
  describe '::get' do
    it 'performs a GET request' do
      stub_env('PARTNER_REGISTER_URL', 'https://partner-register.com')
      stub_env('PARTNER_KEY', 'partner-key')
      stub_request(:get, "https://partner-register.com/123")
        .with(
          headers: {
            'Accept' => '*/*',
            'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'Content-Type' => 'application/json',
            'Host' => 'partner-register.com',
            'User-Agent' => 'Ruby',
            'X-Api-Key' => 'partner-key'
          }
        )
        .to_return(status: 200, body: "success", headers: {})
      result = DiaperPartnerClient.get(id: 123)
      expect(result).to eq "success"
    end
  end
end

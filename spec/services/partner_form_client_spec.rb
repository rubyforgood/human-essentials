RSpec.describe DiaperPartnerClient, type: :service do
  before do
    stub_env('PARTNER_FORM_URL', 'https://partner-form.com')
    stub_env('PARTNER_KEY', 'partner-key')
  end

  describe '::post' do
    it 'performs a POST request' do
      attributes = { 'id' => 123, 'partner_form_fields' => %w(section1 section2) }
      stub_partner_request
      result = PartnerFormClient.post(attributes)
      expect(result).to eq 'success'
    end
  end

  private

  def stub_partner_request
    stub_request(:post, "https://partner-form.com/")
      .with(
        body: "{\"partner_form\":{\"diaper_bank_id\":123,\"sections\":[\"section1\",\"section2\"]}}",
        headers: {
          'Accept' => '*/*',
          'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Content-Type' => 'application/json',
          'Host' => 'partner-form.com',
          'User-Agent' => 'Ruby',
          'X-Api-Key' => 'partner-key'
        }
      )
      .to_return(status: 200, body: "success", headers: {})
  end
end

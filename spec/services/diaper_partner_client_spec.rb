RSpec.describe DiaperPartnerClient, type: :service do
  before do
    stub_env('PARTNER_REGISTER_URL', 'https://partner-register.com')
    stub_env('PARTNER_KEY', 'partner-key')
  end

  describe '::post' do
    it 'performs a POST request' do
      attributes = { 'id' => 123, 'organization_id' => 456, 'email' => 'foo@bar.com' }
      invitation_text = 'invitation'
      expected_body = {
        partner:
        {
          diaper_bank_id: attributes["organization_id"],
          diaper_partner_id: attributes["id"],
          invitation_text: invitation_text,
          email: attributes["email"]
        }
      }.to_json
      stub_partner_request(:post, 'https://partner-register.com/', body: expected_body)
      result = DiaperPartnerClient.post(attributes, invitation_text)
      expect(result.is_a?(Net::HTTPSuccess)).to eq(true)
    end
  end

  describe '::get' do
    let(:fake_random_id) { Faker::Number.number }

    it 'performs a GET request' do
      stub_partner_request(:get, "https://partner-register.com/#{fake_random_id}")
      result = DiaperPartnerClient.get(id: fake_random_id)
      expect(result).to eq 'success'
    end

    context 'with query_params' do
      let(:query_params) { { impact_metrics: true } }

      it 'performs a GET request' do
        stub_partner_request(:get, "https://partner-register.com/#{fake_random_id}?impact_metrics=true")
        result = DiaperPartnerClient.get({ id: fake_random_id }, query_params: query_params)
        expect(result).to eq 'success'
      end
    end
  end

  describe '::put' do
    it 'performs a PUT request' do
      attributes = { partner_id: 123, status: 'status' }
      expected_body = {
        partner: {
          diaper_partner_id: attributes[:partner_id],
          status: attributes[:status]
        }
      }.to_json
      stub_partner_request(:put, 'https://partner-register.com/123', body: expected_body)
      result = DiaperPartnerClient.put(attributes)
      expect(result.body).to eq 'success'
    end
  end

  private

  def stub_partner_request(method, url, request = {}, response = {})
    stub_request(method, url)
      .with({
        headers: {
          'Accept' => '*/*',
          'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Content-Type' => 'application/json',
          'Host' => 'partner-register.com',
          'User-Agent' => 'Ruby',
          'X-Api-Key' => 'partner-key'
        }
      }.merge(request))
      .to_return({ status: 200, body: 'success', headers: {} }.merge(response))
  end
end

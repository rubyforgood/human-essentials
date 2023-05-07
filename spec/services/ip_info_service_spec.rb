RSpec.describe "IpInfo Service" do
	context "returns ipinfo to retrieve time zone" do
		before do
			stub_request(:get, "https://ipinfo.io/json").
				with(
					headers: {
								'Accept'=>'*/*',
								'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
								'User-Agent'=>'Faraday v1.10.2'
					}).
				to_return(status: 200, body: "{\n  \"ip\": \"0.0.0.0\",\n  \"hostname\": \"host.name\",\n  \"city\": \"Denver\",\n  \"region\": \"Colorado\",\n  \"country\": \"US\",\n  \"loc\": \"coordinates\",\n  \"org\": \"ISP Provider\",\n  \"postal\": \"00000\",\n  \"timezone\": \"America/Denver\",\n  \"readme\": \"readme\"\n}", headers: {})
		end

		let(:timezone) { IpInfoService.get_timezone }

		it "collects time zone for mailer" do
			expect(timezone).to eq("America/Denver")
		end
	end
end
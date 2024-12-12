RSpec.describe "DonationSites", type: :request do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }

  describe "while signed in" do
    before do
      sign_in(user)
    end

    describe "GET #index" do
      subject do
        get donation_sites_path(format: response_format)
        response
      end

      before do
        create(:donation_site)
      end

      context "html" do
        let(:response_format) { 'html' }

        it { is_expected.to be_successful }
      end

      context "csv" do
        let(:response_format) { 'csv' }

        it { is_expected.to be_successful }
      end
    end
    describe 'GET #index' do
      let!(:active_donation_site) { create(:donation_site, organization: organization, name: "An Active Site") }
      let!(:inactive_donation_site) { create(:donation_site, organization: organization, active: false, name: "An Inactive Site") }

      it "should show all/only active donation sites with deactivate buttons" do
        get donation_sites_path
        page = Nokogiri::HTML(response.body)
        expect(response.body).to include("An Active Site")
        expect(response.body).not_to include("An Inactive Site")
        button1 = page.css(".btn[href='/donation_sites/#{active_donation_site.id}/deactivate']")
        expect(button1.text.strip).to eq("Deactivate")
        expect(button1.attr('class')).not_to match(/disabled/)
      end
    end

    describe 'DELETE #deactivate' do
      it 'should be able to deactivate an item' do
        donation_site = create(:donation_site, organization: organization, active: true, name: "to be deactivated")
        params = { id: donation_site.id }

        expect { delete deactivate_donation_site_path(params) }.to change { donation_site.reload.active }.from(true).to(false)
        expect(response).to redirect_to(donation_sites_path)
      end
    end
  end
end

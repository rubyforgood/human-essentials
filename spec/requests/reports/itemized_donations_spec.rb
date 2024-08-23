RSpec.describe "Reports::ItemizedDonations", type: :request do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }

  describe "while signed in" do
    before do
      sign_in user
    end

    describe "GET #index" do
      subject do
        get reports_itemized_donations_path(format: response_format)
        response
      end
      let(:response_format) { "html" }

      it { is_expected.to have_http_status(:success) }
    end

    context "without any donations" do
      it "can load the page" do
        get reports_itemized_donations_path
        expect(response.body).to include("Itemized Donations")
      end

      it "has no items" do
        get reports_itemized_donations_path
        expect(response.body).to include("No itemized donations found for the selected date range.")
      end
    end

    context "with a donation" do
      let(:donation) { create(:donation, :with_items, organization: organization) }

      it "Shows an item from the donation" do
        donation
        get reports_itemized_donations_path
        expect(response.body).to include(donation.items.first.name)
      end
    end
  end

  describe "while not signed in" do
    describe "GET /index" do
      subject do
        get reports_itemized_donations_path
        response
      end

      it "redirect to login" do
        is_expected.to redirect_to(new_user_session_path)
      end
    end
  end
end

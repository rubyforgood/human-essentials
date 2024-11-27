RSpec.describe "Reports::ManufacturerDonationsSummary", type: :request do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:manufacturer1) { create(:manufacturer, organization: organization, name: "Manufacturer 1") }
  let(:manufacturer2) { create(:manufacturer, organization: organization, name: "Manufacturer 2") }
  let(:manufacturer3) { create(:manufacturer, organization: organization, name: "Manufacturer 3") }

  describe "while signed in" do
    before do
      sign_in user
    end

    describe "GET #index" do
      subject do
        get reports_manufacturer_donations_summary_path(format: "html")
        response
      end

      it { is_expected.to have_http_status(:success) }
    end

    context "when visiting the summary page" do
      it "has a link to create a new donation" do
        get reports_manufacturer_donations_summary_path

        expect(response.body).to include("New Donation")
        expect(response.body).to include("#{@url_prefix}/donations/new")
      end

      context "with manufacturer donations in the last year" do
        let(:formatted_date_range) { date_range.map { _1.to_formatted_s(:date_picker) }.join(" - ") }
        let(:date_range) { [1.year.ago, 0.days.ago] }
        let!(:donations) do
          [
            create(:donation, :with_items, item_quantity: 2, issued_at: 5.days.ago, organization: organization, source: "Manufacturer", manufacturer: manufacturer1),
            create(:donation, :with_items, item_quantity: 3, issued_at: 3.months.ago, organization: organization, source: "Manufacturer", manufacturer: manufacturer1),
            create(:donation, :with_items, item_quantity: 7, issued_at: 2.years.ago, organization: organization, source: "Manufacturer", manufacturer: manufacturer2),
            create(:donation, :with_items, item_quantity: 1, issued_at: 0.days.ago, organization: organization, source: "Manufacturer", manufacturer: manufacturer2),
            create(:donation, :with_items, item_quantity: 13, issued_at: 20.days.ago, organization: organization, source: "Manufacturer", manufacturer: manufacturer3),
            create(:donation, :with_items, item_quantity: 17, issued_at: 5.years.ago, organization: organization, source: "Manufacturer", manufacturer: manufacturer3)
          ]
        end

        it "shows correct total received donations" do
          get reports_manufacturer_donations_summary_path(user.organization), params: {filters: {date_range: formatted_date_range}}

          expect(response.body).to match(%r{<span class="total_received_donations">\s*19\s*</span>})
        end

        it "shows correct individual donations for each manufacturer" do
          get reports_manufacturer_donations_summary_path(user.organization), params: {filters: {date_range: formatted_date_range}}

          expect(response.body).to match(%r{Manufacturer 1 \(5\)})
          expect(response.body).to match(%r{Manufacturer 2 \(1\)})
          expect(response.body).to match(%r{Manufacturer 3 \(13\)})
        end

        it "shows top manufacturers in desc. order" do
          get reports_manufacturer_donations_summary_path(user.organization), params: {filters: {date_range: formatted_date_range}}

          expect(response.body).to match(%r{Manufacturer 3 .* Manufacturer 1 .*Manufacturer 2}m)
        end
      end
    end
  end

  describe "while not signed in" do
    describe "GET /index" do
      subject do
        get reports_manufacturer_donations_summary_path
        response
      end

      it "redirect to login" do
        is_expected.to redirect_to(new_user_session_path)
      end
    end
  end
end

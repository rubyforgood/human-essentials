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

        expect(response.body).to include("New donation")
        expect(response.body).to include("/donations/new")
      end

      context "with manufacturer donations in the last year" do
        let(:formatted_date_range) { date_range.map { it.to_fs(:date_picker) }.join(" - ") }
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

        it "shows each manufacturer's items in its own cell" do
          # It was "Manufacturer 1 (5)" -- a bare parenthesised figure with no unit, which is
          # sum(line_items.quantity) and so counts items rather than donations. The page is a table
          # now, so the figure is in a column that names it.
          get reports_manufacturer_donations_summary_path(user.organization), params: {filters: {date_range: formatted_date_range}}

          expect(response.body).to include("Items donated")
          %w[Manufacturer\ 1 Manufacturer\ 2 Manufacturer\ 3].each do |name|
            expect(response.body).to include(name.tr("\\", ""))
          end
          expect(response.body).to match(%r{<td class="quantity">13</td>})
          expect(response.body).to match(%r{<td class="quantity">5</td>})
          expect(response.body).to match(%r{<td class="quantity">1</td>})
        end

        it "shows manufacturers largest first" do
          # Was "desc. order of most recent donation", and the page showed no dates at all -- so the
          # ordering was invisible. The report is a summary of who gives most; the date has a column
          # of its own now, and which period it covers is the date filter's job.
          get reports_manufacturer_donations_summary_path(user.organization), params: {filters: {date_range: formatted_date_range}}

          expect(response.body).to match(%r{Manufacturer 3.*Manufacturer 1.*Manufacturer 2}m)
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

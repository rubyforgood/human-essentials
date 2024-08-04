RSpec.describe "Reports::ProductDrivesSummary", type: :request do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }

  describe "while signed in" do
    before do
      sign_in user
    end

    describe "GET #index" do
      subject do
        get reports_product_drives_summary_path(format: response_format)
        response
      end
      let(:response_format) { "html" }

      it { is_expected.to have_http_status(:success) }
    end

    context "with filters" do
      before do
        # Create a bunch of historical product_drives
        create :product_drive_donation, :with_items, item_quantity: 2, money_raised: 700, issued_at: 0.days.ago, organization: organization
        create :product_drive_donation, :with_items, item_quantity: 3, money_raised: 700, issued_at: 1.day.ago, organization: organization
        create :product_drive_donation, :with_items, item_quantity: 7, money_raised: 700, issued_at: 3.days.ago, organization: organization
        create :product_drive_donation, :with_items, item_quantity: 11, money_raised: 700, issued_at: 10.days.ago, organization: organization
        create :product_drive_donation, :with_items, item_quantity: 13, money_raised: 700, issued_at: 20.days.ago, organization: organization
        create :product_drive_donation, :with_items, item_quantity: 17, money_raised: 700, issued_at: 30.days.ago, organization: organization

        create :product_drive_donation, :with_items, item_quantity: 12, money_raised: 1700, issued_at: 0.days.ago, organization: organization
        create :product_drive_donation, :with_items, item_quantity: 13, money_raised: 1700, issued_at: 1.day.ago, organization: organization
        create :product_drive_donation, :with_items, item_quantity: 17, money_raised: 1700, issued_at: 3.days.ago, organization: organization
        create :product_drive_donation, :with_items, item_quantity: 111, money_raised: 1700, issued_at: 10.days.ago, organization: organization
        create :product_drive_donation, :with_items, item_quantity: 113, money_raised: 1700, issued_at: 20.days.ago, organization: organization
        create :product_drive_donation, :with_items, item_quantity: 117, money_raised: 1700, issued_at: 30.days.ago, organization: organization
      end

      let(:formatted_date_range) { date_range.map { _1.to_formatted_s(:date_picker) }.join(" - ") }

      before do
        get reports_product_drives_summary_path(user.organization), params: {filters: {date_range: formatted_date_range}}
      end

      context "today" do
        let(:date_range) { [0.days.ago, 0.days.ago] }
        it "shows the correct total and links" do
          expect(response.body).to match(%r{<span class="total_received_donations">\s*14\s*</span>})
          expect(response.body).to match(%r{<span class="total_money_raised">\s*\$24.00\s*</span>})
        end
      end

      context "yesterday" do
        let(:date_range) { [1.day.ago, 1.day.ago] }
        it "shows the correct total and links" do
          expect(response.body).to match(%r{<span class="total_received_donations">\s*16\s*</span>})
          expect(response.body).to match(%r{<span class="total_money_raised">\s*\$24.00\s*</span>})
        end
      end

      context "a weekish ago" do
        let(:date_range) { [14.days.ago, 7.days.ago] }
        it "shows the correct total and links" do
          expect(response.body).to match(%r{<span class="total_received_donations">\s*122\s*</span>})
          expect(response.body).to match(%r{<span class="total_money_raised">\s*\$24.00\s*</span>})
        end
      end

      context "two weekish ago" do
        let(:date_range) { [25.days.ago, 7.days.ago] }
        it "shows the correct total and links" do
          expect(response.body).to match(%r{<span class="total_received_donations">\s*248\s*</span>})
          expect(response.body).to match(%r{<span class="total_money_raised">\s*\$48.00\s*</span>})
        end
      end

      context "a long time" do
        let(:date_range) { [900.days.ago, 1.day.ago] }
        it "shows the correct total and links" do
          expect(response.body).to match(%r{<span class="total_received_donations">\s*422\s*</span>})
          expect(response.body).to match(%r{<span class="total_money_raised">\s*\$120.00\s*</span>})
        end
      end
    end
  end

  describe "while not signed in" do
    describe "GET /index" do
      subject do
        get reports_product_drives_summary_path
        response
      end

      it "redirect to login" do
        is_expected.to redirect_to(new_user_session_path)
      end
    end
  end
end

RSpec.describe "Purchases", type: :request do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }

  context "while signed in" do
    before do
      sign_in(user)
    end

    describe "GET #index" do
      it "shows a list of recent purchases" do
        get reports_purchases_summary_path
        expect(response.body).to include("Recent purchases")
      end
    end

    context "with filters" do
      before do
        # Create a bunch of historical purchases
        create :purchase, :with_items, item_quantity: 2, issued_at: 0.days.ago, organization: organization
        create :purchase, :with_items, item_quantity: 3, issued_at: 1.day.ago, organization: organization
        create :purchase, :with_items, item_quantity: 7, issued_at: 3.days.ago, organization: organization
        create :purchase, :with_items, item_quantity: 11, issued_at: 10.days.ago, organization: organization
        create :purchase, :with_items, item_quantity: 13, issued_at: 20.days.ago, organization: organization
        create :purchase, :with_items, item_quantity: 17, issued_at: 30.days.ago, organization: organization
      end

      let(:formatted_date_range) { date_range.map { _1.to_formatted_s(:date_picker) }.join(" - ") }

      before do
        get reports_purchases_summary_path, params: {filters: {date_range: formatted_date_range}}
      end

      context "today" do
        let(:date_range) { [0.days.ago, 0.days.ago] }
        it "shows the correct total and links" do
          expect(response.body).to include("2 items from")
        end
      end

      context "yesterday" do
        let(:date_range) { [1.day.ago, 1.day.ago] }
        it "shows the correct total and links" do
          expect(response.body).to include("3 items from")
        end
      end

      context "a weekish ago" do
        let(:date_range) { [14.days.ago, 7.days.ago] }
        it "shows the correct total and links" do
          expect(response.body).to include("11 items from")
        end
      end

      context "two weekish ago" do
        let(:date_range) { [25.days.ago, 7.days.ago] }
        it "shows the correct total and links" do
          expect(response.body).to include("11 items from")
          expect(response.body).to include("13 items from")
        end
      end

      context "a long time" do
        let(:date_range) { [900.days.ago, 1.day.ago] }
        it "shows the correct total and links" do
          expect(response.body).to include("$50.00")
          expect(response.body).to include("3 items from")
          expect(response.body).to include("7 items from")
          expect(response.body).to include("11 items from")
        end
      end
    end
  end

  context "while not signed in" do
    describe "GET #index" do
      it "redirects user to sign in page" do
        get reports_purchases_summary_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end

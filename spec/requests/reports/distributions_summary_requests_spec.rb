RSpec.describe "Distributions", type: :request do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }

  context "while signed in" do
    before do
      travel_to("2024-01-17")
    end

    before do
      sign_in(user)
    end

    context "the index page" do
      context "without filters" do
        before do
          get reports_distributions_summary_path(user.organization)
        end

        it "shows a list of recent distributions" do
          expect(response.body).to include("Recent distributions")
        end

        it "has a link to create a new distribution" do
          expect(response.body).to include("distributions/new")
        end
      end

      context "with filters" do
        before do
          # Create a bunch of historical distributions
          create :distribution, :with_items, item_quantity: 2, issued_at: 0.days.ago, organization: organization
          create :distribution, :with_items, item_quantity: 3, issued_at: 1.day.ago, organization: organization
          create :distribution, :with_items, item_quantity: 7, issued_at: 3.days.ago, organization: organization
          create :distribution, :with_items, item_quantity: 11, issued_at: 10.days.ago, organization: organization
          create :distribution, :with_items, item_quantity: 13, issued_at: 20.days.ago, organization: organization
          create :distribution, :with_items, item_quantity: 17, issued_at: 30.days.ago, organization: organization
        end

        let(:formatted_date_range) { date_range.map { _1.to_formatted_s(:date_picker) }.join(" - ") }

        before do
          get reports_distributions_summary_path, params: {filters: {date_range: formatted_date_range}}
        end

        context "today" do
          let(:date_range) { [0.days.ago, 0.days.ago] }
          it "shows the correct total and links" do
            expect(response.body).to match(%r{<span class="total_distributed">\s*2\s*</span>})
          end
        end

        context "yesterday" do
          let(:date_range) { [1.day.ago, 1.day.ago] }
          it "shows the correct total and links" do
            expect(response.body).to match(%r{<span class="total_distributed">\s*3\s*</span>})
          end
        end

        context "a weekish ago" do
          let(:date_range) { [14.days.ago, 7.days.ago] }
          it "shows the correct total and links" do
            expect(response.body).to match(%r{<span class="total_distributed">\s*11\s*</span>})
          end
        end

        context "two weekish ago" do
          let(:date_range) { [25.days.ago, 7.days.ago] }
          it "shows the correct total and links" do
            expect(response.body).to match(%r{<span class="total_distributed">\s*24\s*</span>})
          end
        end

        context "a long time" do
          let(:date_range) { [900.days.ago, 1.day.ago] }
          it "shows the correct total and links" do
            expect(response.body).to match(%r{<span class="total_distributed">\s*51\s*</span>})
          end
        end
      end
    end
  end

  context "while not signed in" do
    describe "GET #index" do
      it "redirects user to sign in page" do
        get reports_distributions_summary_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end

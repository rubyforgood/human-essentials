RSpec.describe "Report Itemized Donations", type: :system, js: true do
  context "With an existing essentials bank" do
    before do
      sign_in(@user)
    end

    context "without any donations" do
      it "can load the page" do
        visit reports_itemized_donations_path(@organization)
        expect(page).to have_content("Itemized Donations")
      end

      it "has no items" do
        visit reports_itemized_donations_path(@organization)
        expect(page).to have_content("No itemized donations found for the selected date range.")
      end
    end

    context "with a donation" do
      let(:donation) { create(:donation, :with_items, organization: @organization) }

      it "Shows an item from the donation" do
        donation
        visit reports_itemized_donations_path(@organization)
        expect(page).to have_content(donation.items.first.name)
      end
    end
  end
end

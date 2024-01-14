RSpec.describe "Report Itemized Distributions", type: :system, js: true do
  context "With an existing essentials bank" do
    before do
      sign_in(@user)
    end

    context "without any distributions" do
      it "can load the page" do
        visit reports_itemized_distributions_path(@organization)
        expect(page).to have_content("Itemized Distributions")
      end

      it "has no items" do
        visit reports_itemized_distributions_path(@organization)
        expect(page).to have_content("No itemized distributions found for the selected date range.")
      end
    end

    context "with a distribution" do
      let(:distribution) { create(:distribution, :with_items, organization: @organization) }

      it "Shows an item from the distribution" do
        distribution
        visit reports_itemized_distributions_path(@organization)
        expect(page).to have_content(distribution.items.first.name)
      end
    end
  end
end

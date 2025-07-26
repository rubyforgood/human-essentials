require "rails_helper"

RSpec.describe "Partner Profile Agency Type Field Visibility", type: :system, js: true do
  let(:partner) { create(:partner) }

  before do
    Flipper.enable(:partner_step_form)
    sign_in(partner.primary_user)
  end

  after do
    Flipper.disable(:partner_step_form)
  end

  context "when selecting different agency types" do
    it "hides Other Agency Type field when non-other agency type is selected" do
      visit edit_partners_profile_path

      find("button[data-bs-target='#agency_information']").click

      select "Food bank/pantry", from: "Agency Type"

      expect(page).to have_css('[data-hide-by-source-val-target="destination"].d-none', visible: false, wait: 5)
    end

    it "shows Other Agency Type field when Other is selected" do
      visit edit_partners_profile_path

      find("button[data-bs-target='#agency_information']").click

      select "Other", from: "Agency Type"

      expect(page).not_to have_css('[data-hide-by-source-val-target="destination"].d-none', visible: false, wait: 5)
    end
  end

  context "on page load" do
    it "hides Other Agency Type field when partner has no agency type" do
      partner.profile.update!(agency_type: nil)

      visit edit_partners_profile_path

      find("button[data-bs-target='#agency_information']").click

      expect(page).to have_css('[data-hide-by-source-val-target="destination"].d-none', visible: false, wait: 5)
    end

    it "hides Other Agency Type field when partner has non-other agency type" do
      partner.profile.update!(agency_type: "food")

      visit edit_partners_profile_path

      find("button[data-bs-target='#agency_information']").click

      expect(page).to have_css('[data-hide-by-source-val-target="destination"].d-none', visible: false, wait: 5)
    end

    it "shows Other Agency Type field when partner has other agency type" do
      partner.profile.update!(agency_type: "other")

      visit edit_partners_profile_path

      find("button[data-bs-target='#agency_information']").click

      expect(page).not_to have_css('[data-hide-by-source-val-target="destination"].d-none', visible: false, wait: 5)
    end
  end
end

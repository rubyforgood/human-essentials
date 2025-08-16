require "rails_helper"

RSpec.describe "Partner Profile Agency Type Field Visibility", type: :system, js: true do
  let(:partner) { create(:partner) }

  before do
    Flipper.enable(:partner_step_form)
    sign_in(partner.primary_user)
    visit edit_partners_profile_path
    find("button[data-bs-target='#agency_information']").click
  end

  after do
    Flipper.disable(:partner_step_form)
  end

  it "shows/hides Other Agency Type field based on selection and initial state" do
    select "Food bank/pantry", from: "Agency Type"
    expect(page).to have_css('[data-hide-by-source-val-target="destination"].d-none', visible: false, wait: 5)

    select "Other", from: "Agency Type"
    expect(page).not_to have_css('[data-hide-by-source-val-target="destination"].d-none', visible: false, wait: 5)
  end

  context "initial state based on partner agency type" do
    it "handles different initial agency types correctly" do
      partner.profile.update!(agency_type: nil)
      visit edit_partners_profile_path
      find("button[data-bs-target='#agency_information']").click
      expect(page).to have_css('[data-hide-by-source-val-target="destination"].d-none', visible: false, wait: 5)

      partner.profile.update!(agency_type: "food")
      visit edit_partners_profile_path
      find("button[data-bs-target='#agency_information']").click
      expect(page).to have_css('[data-hide-by-source-val-target="destination"].d-none', visible: false, wait: 5)

      partner.profile.update!(agency_type: "other")
      visit edit_partners_profile_path
      find("button[data-bs-target='#agency_information']").click
      expect(page).not_to have_css('[data-hide-by-source-val-target="destination"].d-none', visible: false, wait: 5)
    end
  end
end

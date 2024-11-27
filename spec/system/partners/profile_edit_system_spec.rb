RSpec.describe "Partners profile edit", type: :system, js: true do
  let!(:partner1) { create(:partner, status: "invited") }
  let(:partner1_user) { partner1.primary_user }

  context "step-wise editing is enabled" do
    before do
      Flipper.enable(:partner_step_form)
      login_as(partner1_user)
      visit edit_partners_profile_path
    end

    it "displays all sections in a closed state by default" do
      within ".accordion" do
        expect(page).to have_css("#agency_information.accordion-collapse.collapse", visible: false)
        expect(page).to have_css("#program_delivery_address.accordion-collapse.collapse", visible: false)

        partner1.partials_to_show.each do |partial|
          expect(page).to have_css("##{partial}.accordion-collapse.collapse", visible: false)
        end

        expect(page).to have_css("#partner_settings.accordion-collapse.collapse", visible: false)
      end
    end

    it "allows sections to be opened, closed, filled in any order, and submit for approval" do
      # Media
      find("button[data-bs-target='#media_information']").click
      expect(page).to have_css("#media_information.accordion-collapse.collapse.show", visible: true)
      within "#media_information" do
        fill_in "Website", with: "https://www.example.com"
      end
      find("button[data-bs-target='#media_information']").click
      expect(page).to have_css("#media_information.accordion-collapse.collapse", visible: false)

      # Executive director
      find("button[data-bs-target='#executive_director']").click
      expect(page).to have_css("#executive_director.accordion-collapse.collapse.show", visible: true)
      within "#executive_director" do
        fill_in "Executive Director Name", with: "Lisa Smith"
      end

      # Save Progress
      all("input[type='submit'][value='Save Progress']").last.click
      expect(page).to have_css(".alert-success", text: "Details were successfully updated.")

      # Submit and Review
      all("input[type='submit'][value='Save and Review']").last.click
      expect(current_path).to eq(partners_profile_path)
      expect(page).to have_css(".alert-success", text: "Details were successfully updated.")
    end

    it "displays the edit view with sections containing validation errors expanded" do
      # Open up Media section and clear out website value
      find("button[data-bs-target='#media_information']").click
      within "#media_information" do
        fill_in "Website", with: ""
      end

      # Open Pick up person section and fill in 4 email addresses
      find("button[data-bs-target='#pick_up_person']").click
      within "#pick_up_person" do
        fill_in "Pick Up Person's Email", with: "email1@example.com, email2@example.com, email3@example.com, email4@example.com"
      end

      # Open Partner Settings section and uncheck all options
      find("button[data-bs-target='#partner_settings']").click
      within "#partner_settings" do
        uncheck "Enable Quantity-based Requests" if has_checked_field?("Enable Quantity-based Requests")
        uncheck "Enable Child-based Requests (unclick if you only do bulk requests)" if has_checked_field?("Enable Child-based Requests (unclick if you only do bulk requests)")
        uncheck "Enable Requests for Individuals" if has_checked_field?("Enable Requests for Individuals")
      end

      # Save Progress
      all("input[type='submit'][value='Save Progress']").last.click

      # Expect an alert-danger message containing validation errors
      expect(page).to have_css(".alert-danger", text: /There is a problem/)
      expect(page).to have_content("No social media presence must be checked if you have not provided any of Website, Twitter, Facebook, or Instagram.")
      expect(page).to have_content("Enable child based requests At least one request type must be set")
      expect(page).to have_content("Pick up email can't have more than three email addresses")

      # Expect media section, executive director section, and partner settings section to be opened
      expect(page).to have_css("#media_information.accordion-collapse.collapse.show", visible: true)
      expect(page).to have_css("#pick_up_person.accordion-collapse.collapse.show", visible: true)
      expect(page).to have_css("#partner_settings.accordion-collapse.collapse.show", visible: true)

      # Try to Submit and Review from error state
      all("input[type='submit'][value='Save and Review']").last.click

      # Expect an alert-danger message containing validation errors
      expect(page).to have_css(".alert-danger", text: /There is a problem/)
      expect(page).to have_content("No social media presence must be checked if you have not provided any of Website, Twitter, Facebook, or Instagram.")
      expect(page).to have_content("Enable child based requests At least one request type must be set")
      expect(page).to have_content("Pick up email can't have more than three email addresses")

      # Expect media section, executive director section, and partner settings section to be opened
      expect(page).to have_css("#media_information.accordion-collapse.collapse.show", visible: true)
      expect(page).to have_css("#pick_up_person.accordion-collapse.collapse.show", visible: true)
      expect(page).to have_css("#partner_settings.accordion-collapse.collapse.show", visible: true)
    end
  end
end

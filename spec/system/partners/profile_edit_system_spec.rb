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
        expect(page).to have_css("#agency_information", visible: :hidden)
        expect(page).to have_css("#program_delivery_address", visible: :hidden)

        partner1.partials_to_show.each do |partial|
          expect(page).to have_css("##{partial}", visible: :hidden)
        end

        expect(page).to have_css("#partner_settings", visible: :hidden)
      end
    end

    it "allows sections to be opened, closed, filled in any order, and submit for approval" do
      # Media
      find("button[aria-controls='media_information']").click
      expect(page).to have_css("#media_information", visible: :visible)
      within "#media_information" do
        fill_in "Website", with: "https://www.example.com"
      end
      find("button[aria-controls='media_information']").click
      expect(page).to have_css("#media_information", visible: :hidden)

      # Contacts
      find("button[aria-controls='contacts']").click
      expect(page).to have_css("#contacts", visible: :visible)
      within "#contacts" do
        fill_in "Executive director name", with: "Lisa Smith"
      end

      # Save Progress
      all("input[type='submit'][value='Save progress']").last.click
      expect(page).to have_css("[data-flash-tone='success']", text: "Details were successfully updated.")

      # Submit and Review
      all("input[type='submit'][value='Save and review']").last.click
      expect(current_path).to eq(partners_profile_path)
      expect(page).to have_css("[data-flash-tone='success']", text: "Details were successfully updated.")
    end

    it "displays the edit view with sections containing validation errors expanded" do
      # Open up Media section and clear out website value
      find("button[aria-controls='media_information']").click
      within "#media_information" do
        fill_in "Website", with: ""
        uncheck "No social media presence"
      end

      # Open Pick up person section and fill in 4 email addresses
      find("button[aria-controls='pick_up_person']").click
      within "#pick_up_person" do
        fill_in "Pick Up Person's Email", with: "email1@example.com, email2@example.com, email3@example.com, email4@example.com"
      end

      # Open Partner Settings section and uncheck all options
      find("button[aria-controls='partner_settings']").click
      within "#partner_settings" do
        uncheck "Enable quantity-based requests" if has_checked_field?("Enable quantity-based requests")
        uncheck "Enable child-based requests (unclick if you only do bulk requests)" if has_checked_field?("Enable child-based requests (unclick if you only do bulk requests)")
        uncheck "Enable requests by number of individuals" if has_checked_field?("Enable requests by number of individuals")
      end

      # Save Progress
      all("input[type='submit'][value='Save progress']").last.click

      # Expect an alert-danger message containing validation errors
      expect(page).to have_css("[data-flash-tone='danger']", text: /There is a problem/)
      expect(page).to have_content("No social media presence must be checked if you have not provided any of Website, Twitter, Facebook, or Instagram.")
      expect(page).to have_content("Enable child based requests At least one request type must be set")
      expect(page).to have_content("Pick up email can't have more than three email addresses")

      # Expect media section, pick up person section, and partner settings section to be opened
      expect(page).to have_css("#media_information", visible: :visible)
      expect(page).to have_css("#pick_up_person", visible: :visible)
      expect(page).to have_css("#partner_settings", visible: :visible)

      # Try to Submit and Review from error state
      all("input[type='submit'][value='Save and review']").last.click

      # Expect an alert-danger message containing validation errors
      expect(page).to have_css("[data-flash-tone='danger']", text: /There is a problem/)
      expect(page).to have_content("No social media presence must be checked if you have not provided any of Website, Twitter, Facebook, or Instagram.")
      expect(page).to have_content("Enable child based requests At least one request type must be set")
      expect(page).to have_content("Pick up email can't have more than three email addresses")

      # Expect media section, pick up person section, and partner settings section to be opened
      expect(page).to have_css("#media_information", visible: :visible)
      expect(page).to have_css("#pick_up_person", visible: :visible)
      expect(page).to have_css("#partner_settings", visible: :visible)
    end

    it "preserves previously uploaded documents when adding new attachments" do
      # Open attached documents section
      find("button[aria-controls='attached_documents']").click
      expect(page).to have_css("#attached_documents", visible: :visible)

      # Upload the first document
      within "#attached_documents" do
        attach_file("partner_profile_documents", Rails.root.join("spec/fixtures/files/document1.md"), make_visible: true)
      end

      # Save Progress
      all("input[type='submit'][value='Save progress']").last.click
      expect(page).to have_css("[data-flash-tone='success']", text: "Details were successfully updated.")

      # Verify the document is listed
      visit edit_partners_profile_path
      find("button[aria-controls='attached_documents']").click
      within "#attached_documents" do
        expect(page).to have_link("document1.md")
      end

      # Upload a second document
      within "#attached_documents" do
        attach_file("partner_profile_documents", Rails.root.join("spec/fixtures/files/document2.md"), make_visible: true)
      end

      # Save Progress
      all("input[type='submit'][value='Save progress']").last.click
      expect(page).to have_css("[data-flash-tone='success']", text: "Details were successfully updated.")

      # Verify both documents are listed
      visit edit_partners_profile_path
      find("button[aria-controls='attached_documents']").click
      within "#attached_documents" do
        expect(page).to have_link("document1.md")
        expect(page).to have_link("document2.md")
      end
    end

    it "allows removal of attached documents" do
      # Open attached documents section
      find("button[aria-controls='attached_documents']").click
      expect(page).to have_css("#attached_documents", visible: :visible)

      # Upload multiple documents at once
      within "#attached_documents" do
        attach_file("partner_profile_documents", [
          Rails.root.join("spec/fixtures/files/document1.md"),
          Rails.root.join("spec/fixtures/files/document2.md")
        ], make_visible: true)

        # Verify both documents are displayed in custom selection list
        expect(page).to have_text("Selected files:")
        expect(page).to have_css("[data-file-input-target='list'] li", text: "document1.md")
        expect(page).to have_css("[data-file-input-target='list'] li", text: "document2.md")
      end

      # Save Progress
      all("input[type='submit'][value='Save progress']").last.click
      expect(page).to have_css("[data-flash-tone='success']", text: "Details were successfully updated.")

      # Verify both documents persist after page reload
      visit edit_partners_profile_path
      find("button[aria-controls='attached_documents']").click
      within "#attached_documents" do
        expect(page).to have_link("document1.md")
        expect(page).to have_link("document2.md")
      end

      # Remove the first document
      within "#attached_documents" do
        document_name = "document1.md"
        document_li = find("li.attached-document", text: document_name)
        document_li.find("a", text: "Remove").click
        expect(page).not_to have_selector("li.attached-document", text: document_name)
      end

      # Save Progress
      all("input[type='submit'][value='Save progress']").last.click
      expect(page).to have_css("[data-flash-tone='success']", text: "Details were successfully updated.")

      # Verify only one document remains
      visit edit_partners_profile_path
      find("button[aria-controls='attached_documents']").click
      within "#attached_documents" do
        expect(page).to have_link("document2.md")
        expect(page).not_to have_link("document1.md")
      end
    end

    it "persists individual file upload when there are validation errors" do
      # Open up Agency Information section and upload proof-of-status letter
      find("button[aria-controls='agency_information']").click
      within "#agency_information" do
        expect(find("[data-file-input-label-target='label']", match: :first)).to have_content("Choose file...")
        attach_file("partner_profile_proof_of_partner_status", Rails.root.join("spec/fixtures/files/irs_determination_letter.md"), make_visible: true)
        expect(find("[data-file-input-label-target='label']", match: :first)).to have_content("irs_determination_letter.md")
      end

      # Open Pick up person section and fill in 4 email addresses which will generate a validation error
      find("button[aria-controls='pick_up_person']").click
      within "#pick_up_person" do
        fill_in "Pick Up Person's Email", with: "email1@example.com, email2@example.com, email3@example.com, email4@example.com"
      end

      # Save Progress
      all("input[type='submit'][value='Save progress']").last.click

      # Expect an alert-danger message containing validation errors
      expect(page).to have_css("[data-flash-tone='danger']", text: /There is a problem/)

      # Open up Agency Information section and expect the file field to remember users selection
      # but NOT be persisted because there hasn't yet been a successful form submission.
      find("button[aria-controls='agency_information']").click
      within "#agency_information" do
        expect(find("[data-file-input-label-target='label']", match: :first)).to have_content("irs_determination_letter.md")
        expect(page).not_to have_content("Attached file:")
        expect(page).not_to have_link("irs_determination_letter.md")
      end

      # Fix validation error in Pick up person section: It's already open due to having a validation error
      within "#pick_up_person" do
        fill_in "Pick Up Person's Email", with: "email1@example.com, email2@example.com, email3@example.com"
      end

      # Save Progress
      all("input[type='submit'][value='Save progress']").last.click
      expect(page).to have_css("[data-flash-tone='success']", text: "Details were successfully updated.")

      # Open up Agency Information section and expect file is persisted
      find("button[aria-controls='agency_information']").click
      within "#agency_information" do
        expect(page).to have_content("Attached file:")
        expect(page).to have_link("irs_determination_letter.md", href: /\/rails\/active_storage\/blobs\/redirect\/.+\/irs_determination_letter\.md/)
        expect(find("[data-file-input-label-target='label']", match: :first)).to have_content("irs_determination_letter.md")
      end
    end

    it "persists multiple file uploads when there are validation errors" do
      # Open Pick up person section and fill in 4 email addresses which will generate a validation error
      find("button[aria-controls='pick_up_person']").click
      within "#pick_up_person" do
        fill_in "Pick Up Person's Email", with: "email1@example.com, email2@example.com, email3@example.com, email4@example.com"
      end

      # Open attached documents section
      find("button[aria-controls='attached_documents']").click
      expect(page).to have_css("#attached_documents", visible: :visible)

      # Upload multiple documents
      within "#attached_documents" do
        attach_file("partner_profile_documents", [
          Rails.root.join("spec/fixtures/files/document1.md"),
          Rails.root.join("spec/fixtures/files/document2.md")
        ], make_visible: true)

        # Verify both documents are displayed in custom selection list
        expect(page).to have_css("[data-file-input-target='list'] li", text: "document1.md")
        expect(page).to have_css("[data-file-input-target='list'] li", text: "document2.md")
      end

      # Save Progress
      all("input[type='submit'][value='Save progress']").last.click

      # Expect an alert-danger message containing validation errors
      expect(page).to have_css("[data-flash-tone='danger']", text: /There is a problem/)

      # Open attached documents section
      find("button[aria-controls='attached_documents']").click
      expect(page).to have_css("#attached_documents", visible: :visible)

      # Expect both documents are still displayed in custom list as selected, but nothing is actually attached
      within "#attached_documents" do
        expect(page).to have_text("Selected files:")
        expect(page).to have_css("[data-file-input-target='list'] li", text: "document1.md")
        expect(page).to have_css("[data-file-input-target='list'] li", text: "document2.md")

        expect(page).not_to have_text("Attached files:")
        expect(page).not_to have_link("document1.md")
        expect(page).not_to have_link("document2.md")
      end

      # Fix validation error in Pick up person section: It's already open due to having a validation error
      within "#pick_up_person" do
        fill_in "Pick Up Person's Email", with: "email1@example.com, email2@example.com, email3@example.com"
      end

      # Save Progress
      all("input[type='submit'][value='Save progress']").last.click
      expect(page).to have_css("[data-flash-tone='success']", text: "Details were successfully updated.")

      # Open attached documents section
      find("button[aria-controls='attached_documents']").click
      expect(page).to have_css("#attached_documents", visible: :visible)

      # Expect both documents are now rendered as downloadable links
      # i.e. they've been saved, without user having had to select them again
      within "#attached_documents" do
        expect(page).to have_text("Attached files:")
        expect(page).to have_link("document1.md")
        expect(page).to have_link("document2.md")
      end
    end
  end
end

# That a confirmation is the app's own dialog and never the browser's.
#
# `confirm_dialog_controller.js` catches the click in the capture phase before rails-ujs sees it,
# shows a `<dialog>`, and replays the click if the answer was yes. `spec/support/confirm_dialog.rb`
# drives that dialog, and thirteen spec files use it -- but only for the call sites they happen to
# exercise. Delete on /product_drives/:id had no spec, was reported showing the browser's own box,
# and the reason it could was that the whole mechanism had been rolled out of the working tree: the
# controller, the partial and the test helper were all deleted, and the layouts reverted to not
# rendering the host element. Nothing failed, because nothing looked.
#
# So this asserts the *mechanism* rather than any one call site: the host element exists in both
# shells, and the reported action produces the styled dialog with a message, a danger tone and its
# own verb. `pw bin/design/confirm-audit.js` presses all 59 of them; this pins the ones a rollback
# would take out first.
RSpec.describe "Confirmations", type: :system, js: true do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }

  describe "the host element" do
    it "is in the bank shell, exactly once" do
      sign_in user
      visit dashboard_path
      expect(page).to have_css("[data-controller~='confirm-dialog']", visible: :all, count: 1)
      expect(page).to have_css("dialog[data-confirm-dialog-target='dialog']", visible: :all, count: 1)
    end

    it "is in the partner shell, exactly once" do
      partner = create(:partner, organization: organization, status: :approved)
      login_as(partner.primary_user)
      visit partners_dashboard_path
      expect(page).to have_css("dialog[data-confirm-dialog-target='dialog']", visible: :all, count: 1)
    end
  end

  describe "deleting a product drive" do
    let!(:product_drive) { create(:product_drive, organization: organization) }
    let(:admin) { create(:organization_admin, organization: organization) }

    before do
      sign_in admin
      visit product_drive_path(product_drive)
    end

    it "asks with the app's own dialog rather than the browser's" do
      # If the interception ever fails, rails-ujs raises a native `window.confirm` and there is no
      # `dialog[open]` to find -- which is the shape of the reported defect, and is what makes this
      # a real assertion rather than a restatement of the markup.
      open_record_actions
      click_button "Delete"

      expect(page).to have_css("dialog[open]")
      within("dialog[open]") do
        expect(page).to have_css("[data-confirm-dialog-target='message']",
          text: "permanently remove this product drive")
        # A destructive action gets its own verb, not "OK" -- which is all a native dialog offers.
        expect(page).to have_css("[data-confirm-dialog-target='accept']", text: "Delete")
      end
    end

    it "wears the danger tone on the confirming button" do
      open_record_actions
      click_button "Delete"

      classes = page.find("dialog[open] [data-confirm-dialog-target='accept']")[:class]
      expect(classes).to include("rose")
    end

    it "does nothing when dismissed, and asks again next time" do
      open_record_actions
      expect(dismiss_confirm_dialog { click_button "Delete" }).to include("permanently remove")
      expect(page).to have_current_path(product_drive_path(product_drive))
      expect(ProductDrive.find_by(id: product_drive.id)).to be_present

      # The replay in `accept` strips `data-confirm` and puts it back; if it did not, the second
      # press would go straight through without asking.
      open_record_actions
      click_button "Delete"
      expect(page).to have_css("dialog[open]")
    end
  end

  # The record's Edit and Delete live in the page header's overflow -- see
  # `essentials_record_actions` and "A record owns its actions" in design.md.
  def open_record_actions
    find("[data-page-header='actions'] button[aria-haspopup='true']").click
  end
end

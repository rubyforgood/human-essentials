# The app confirms with its own `<dialog>`, not `window.confirm` -- see design.md and
# `confirm_dialog_controller.js`. Capybara's `accept_confirm_dialog` drives a *native* dialog, so it has
# nothing to accept here and would hang waiting for one.
#
# These mirror its contract, including returning the message, so an assertion like
#
#   expect(accept_confirm_dialog { click_row_action "Deactivate" }).to include "Are you sure"
#
# reads the same as the version it replaced.
module ConfirmDialog
  # Run the block, then press the dialog's confirm button. Returns the message it showed.
  def accept_confirm_dialog
    yield if block_given?
    dialog = page.document.find("dialog[open]")
    message = dialog.find("[data-confirm-dialog-target='message']").text
    dialog.find("[data-confirm-dialog-target='accept']").click
    # The dialog closes and the form submits; waiting here keeps the next assertion from racing it.
    expect(page.document).to have_no_css("dialog[open]")
    message
  end

  # Run the block, then dismiss. Returns the message.
  def dismiss_confirm_dialog
    yield if block_given?
    dialog = page.document.find("dialog[open]")
    message = dialog.find("[data-confirm-dialog-target='message']").text
    dialog.find("button", text: "Cancel").click
    expect(page.document).to have_no_css("dialog[open]")
    message
  end
end

RSpec.configure do |config|
  config.include ConfirmDialog, type: :system
end

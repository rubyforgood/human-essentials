class BankListingMailer < ApplicationMailer
  # Sent to every super admin when the weekly bank finder import keeps last week's list.
  def import_failed(error:)
    @error = error
    recipients = User.with_role(Role::SUPER_ADMIN).pluck(:email)
    return if recipients.empty?

    mail to: recipients, subject: "[Human Essentials] The bank finder kept last week's list"
  end
end

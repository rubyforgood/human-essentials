class CustomDeviseMailer < Devise::Mailer
  protected

  def subject_for(key)
    return super unless key.to_s == 'invitation_instructions'

    # Replace the invitation instruction subject for partner users
    # that were invited by other partner users.

    if resource.partner.present? && resource.roles.size == 1
      "You've been invited to be a partner with #{resource.partner.organization.name}"
    else
      super
    end
  end
end

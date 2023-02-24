class CustomDeviseMailer < Devise::Mailer
  protected

  def subject_for(key)
    return super unless key.to_s == 'invitation_instructions'

    # Replace the invitation instruction subject for partner users
    # that were invited by other partner users.

    if resource.has_role?(Role::PARTNER, :any) && resource.id == resource.partner.primary_user&.id
      "You've been invited to be a partner with #{resource.partner.organization.name}"
    elsif resource.has_role?(Role::PARTNER, :any) && resource.id != resource.partner.primary_user&.id
      "You've been invited to #{resource.partner.name}'s Human Essentials account"
    else
      super
    end
  end
end

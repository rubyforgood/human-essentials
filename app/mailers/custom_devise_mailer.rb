class CustomDeviseMailer < Devise::Mailer
  protected

  def subject_for(key)
    return super unless key.to_s == 'invitation_instructions'

    if resource.is_a?(PartnerUser)
      "You've been invited to be a partner with #{resource.partner.organization.name}"
    else
      super
    end
  end
end

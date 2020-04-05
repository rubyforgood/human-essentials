# Creates a job for indicating that a Partner has been invited, and notifies the PartnerBase system about them
class UpdateDiaperPartnerJob < ApplicationJob
  def perform(partner_id)
    @partner = Partner.find(partner_id)
    @invitation_message = @partner.organization.invitation_text
    @response = DiaperPartnerClient.post(@partner.attributes, @invitation_message) if Flipper.enabled?(:email_active)
    if @response == Net::HTTPSuccess
      @partner.invited!
    else
      @partner.error!
    end
  end
end
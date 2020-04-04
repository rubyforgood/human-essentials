# Creates a job for indicating that a Partner has been invited, and notifies the PartnerBase system about them
class UpdateDiaperPartnerJob
  include Sidekiq::Worker
  include DiaperPartnerClient

  def perform(partner_id)
    @partner = Partner.find(partner_id)
    @invitation_message = @partner.organization.invitation_text
    @response = DiaperPartnerClient.post(partner_attributes, @invitation_message) if Flipper.enabled?(:email_active)
    @partner.invited!
  end

  def partner_attributes
    @partner.attributes
  end
end
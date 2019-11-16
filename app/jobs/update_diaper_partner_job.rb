# Creates a job for indicating that a Partner has been invited, and notifies the PartnerBase system about them
class UpdateDiaperPartnerJob
  include Sidekiq::Worker
  include DiaperPartnerClient

  def perform(partner_id, options = {})
    @partner = Partner.find(partner_id)
    @invitation_message = @partner.organization.invitation_text
    @response = DiaperPartnerClient.post(@partner.attributes.merge(options.stringify_keys), @invitation_message) #if Flipper.enabled?(:email_active)
    @partner.invited!
  end
end
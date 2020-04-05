# Creates a job for indicating that a Partner has been invited, and notifies the PartnerBase system about them
class UpdateDiaperPartnerJob
  include Sidekiq::Worker
  include DiaperPartnerClient

  def perform(partner_id)
    @partner = Partner.find(partner_id)
    @invitation_message = @partner.organization.invitation_text
    @response = DiaperPartnerClient.post(partner_attributes(@partner), @invitation_message) if Flipper.enabled?(:email_active)
    @partner.invited!
  end

  private

  def partner_attributes(partner)
    partner.attributes.merge({ organization_email: partner.organization.email }).with_indifferent_access
  end
end
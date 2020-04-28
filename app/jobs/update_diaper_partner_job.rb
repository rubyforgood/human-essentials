# Creates a job for indicating that a Partner has been invited, and notifies the PartnerBase system about them
class UpdateDiaperPartnerJob < ApplicationJob
  def perform(partner_id)
    @partner = Partner.find(partner_id)
    @invitation_message = @partner.organization.invitation_text

    @response = DiaperPartnerClient.post(partner_attributes(@partner), @invitation_message) if Flipper.enabled?(:email_active)
    if @response.is_a?(Net::HTTPSuccess)
      @partner.invited!
    else
      @partner.error!
    end
  end

  private

  def partner_attributes(partner)
    partner.attributes.merge({ organization_email: partner.organization.email }).with_indifferent_access
  end
end
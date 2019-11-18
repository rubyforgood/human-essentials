class AddDiaperPartnerJob
  include Sidekiq::Worker
  include DiaperPartnerClient

  def perform(partner_id, options = {})
    @partner = Partner.find(partner_id)
    @invitation_message = @partner.organization.invitation_text
    @response = DiaperPartnerClient.add(@partner.attributes.merge(options.stringify_keys), @invitation_message) # if Flipper.enabled?(:email_active)
  end
end

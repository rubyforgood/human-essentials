class UpdateDiaperPartnerJob
  include Sidekiq::Worker
  include DiaperPartnerClient

  def perform(partner_id)
    @partner = Partner.find(partner_id)
    @response = DiaperPartnerClient.post(@partner.attributes) if Flipper.enabled?(:email_active)
    @partner.invited!
  end
end

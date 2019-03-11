class UpdateDiaperPartnerJob
  include Sidekiq::Worker
  include DiaperPartnerClient

  def perform(partner_id)
    @partner = Partner.find(partner_id)
    DiaperPartnerClient.post(@partner.attributes) if Flipper.enabled?(:email_active)
    @partner.update(status: "Pending")
  end
end

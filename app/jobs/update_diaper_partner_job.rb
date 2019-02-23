class UpdateDiaperPartnerJob < ActiveJob::Base
  queue_as :default
  include DiaperPartnerClient
  workers 2

  def perform(partner_id)
    @partner = Partner.find(partner_id)
    DiaperPartnerClient.post(@partner.attributes) if Flipper.enabled?(:email_active)
    @partner.update(status: "Pending")
  end
end

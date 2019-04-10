class UpdateDiaperPartnerJob < ApplicationJob
  include DiaperPartnerClient
  queue_as :default

  def perform(partner_id)
    @partner = Partner.find(partner_id)
    @response = DiaperPartnerClient.post(@partner.attributes) if Flipper.enabled?(:email_active)

    if @response&.value == Net::HTTPSuccess
      @partner.update(status: "Pending")
    else
      @partner.update(status: "Error")
    end
  end
end

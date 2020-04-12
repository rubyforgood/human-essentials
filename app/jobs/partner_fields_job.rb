class PartnerFieldsJob
  include Sidekiq::Worker
  include PartnerFormClient

  def perform(organization_id)
    @organization = Organization.find(organization_id)
    PartnerFormClient.post(@organization.attributes)
  end
end

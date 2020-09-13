class DistributionCreateService < DistributionService
  attr_reader :distribution

  def initialize(distribution_params, request_id = nil)
    @distribution = Distribution.new(distribution_params)
    @request = Request.find(request_id) if request_id
  end

  def call
    perform_distribution_service do
      distribution.save!
      distribution.scheduled!
      distribution.storage_location.decrease_inventory distribution
      distribution.reload
      @request&.update!(distribution_id: distribution.id, status: 'fulfilled')
      send_notification if distribution.partner&.send_reminders
    end
  end

  private

  def send_notification
    PartnerMailerJob.perform_async(distribution_organization.id, distribution.id, 'Your Distribution') if Flipper.enabled?(:email_active)
  end
end

class DistributionCreateService < DistributionService
  attr_reader :distribution

  def initialize(distribution_params, request_id = nil)
    @distribution = Distribution.new(distribution_params)
    @request = Request.find(request_id) if request_id
  end

  def call
    perform_distribution_service do
      validate_request_not_yet_processed! if @request.present?

      distribution.save!
      distribution.storage_location.decrease_inventory distribution
      distribution.reload
      @request&.update!(distribution_id: distribution.id, status: 'fulfilled')
      send_notification if distribution.partner&.send_reminders
    end
  end

  private

  def send_notification
    PartnerMailerJob.perform_later(distribution_organization.id, distribution.id, 'Your Distribution')
  end

  def validate_request_not_yet_processed!
    existing_distribution = @request.distribution
    if existing_distribution.present?
      raise "Request has already been fulfilled by Distribution #{existing_distribution.id}"
    end
  end
end

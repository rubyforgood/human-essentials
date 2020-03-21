class DistributionCreateService
  attr_reader :distribution, :error

  def initialize(distribution_params, request_id = nil)
    @distribution = Distribution.new(distribution_params)
    @request = Request.find(request_id) if request_id
    @organization = @distribution.organization
    @error = nil

  end

  def call
    @distribution.transaction do
      @distribution.save!
      @distribution.scheduled!
      @distribution.storage_location.decrease_inventory @distribution
      @distribution.reload
      @request&.update!(distribution_id: @distribution.id, status: 'fulfilled')
      PartnerMailerJob.perform_async(@organization.id, @distribution.id, 'Your Distribution') if Flipper.enabled?(:email_active)
    end
  rescue Errors::InsufficientAllotment => e
    @distribution.line_items.assign_insufficiency_errors(e.insufficient_items)
    Rails.logger.error "[!] DistributionsController#create failed because of Insufficient Allotment #{@organization.short_name}: #{@distribution.errors.full_messages} [#{e.message}]"
    @error = e
  rescue StandardError => e
    Rails.logger.error "[!] DistributionsController#create failed to save distribution for #{@organization.short_name}: #{@distribution.errors.full_messages} [#{e.inspect}]"
    @error = e
  ensure
    return self
  end

  def success?
    @error.nil?
  end
end

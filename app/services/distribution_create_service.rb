class DistributionCreateService
  def initialize(distribution_params, request_id = nil)
    @distribution = Distribution.new(distribution_params)
    @request = Request.find(request_id) if request_id
    @organization = @distribution.organization
  end

  def call
    @distribution.transaction do
      @distribution.save!
      @distribution.storage_location.decrease_inventory @distribution
      @distribution.reload
      @request&.update!(distribution_id: @distribution.id, status: 'fulfilled')
      PartnerMailerJob.perform_async(@organization, @distribution, subject: 'Your Distribution') if Flipper.enabled?(:email_active)

      OpenStruct.new(success?: true, distribution: @distribution)
    end
  rescue StandardError => e
    Rails.logger.error "[!] DistributionsController#create failed to save distribution for #{@distribution.organization.short_name}: #{@distribution.errors.full_messages} [#{e.inspect}]"
    OpenStruct.new(success: false, distribution: @distribution, error: e)
  end
end

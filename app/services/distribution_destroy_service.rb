class DistributionDestroyService
  def initialize(distribution_id)
    @distribution = Distribution.find(distribution_id)
  end

  def call
    @distribution.transaction do
      @distribution.destroy!
      @distribution.storage_location.increase_inventory @distribution
      OpenStruct.new(success?: true)
    end
  rescue StandardError => e
    Rails.logger.error "[!] DistributionsController#destroy failed to destroy distribution for #{@distribution.organization.short_name}: #{@distribution.errors.full_messages} [#{e.inspect}]"
    OpenStruct.new(success: false, distribution: @distribution, error: e)
  end
end

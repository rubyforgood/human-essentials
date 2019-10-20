class DistributionCreator
  def initialize(distribution)
    @distribution = distribution
  end

  def call
    @distribution.transaction do
      @distribution.save
      @distribution.storage_location.decrease_inventory @distribution
      OpenStruct.new(success?: true)
    end
  rescue StandardError => e
    Rails.logger.error "[!] DistributionsController#create failed to save distribution for #{@distribution.organization.short_name}: #{@distribution.errors.full_messages} [#{e.inspect}]"
    OpenStruct.new(success: false, error: e)
  end
end

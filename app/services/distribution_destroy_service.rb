class DistributionDestroyService
  attr_reader :distribution, :error

  def initialize(distribution_id)
    @distribution_id = distribution_id
  end

  def call
    @distribution = Distribution.find(@distribution_id)
    @organization = distribution.organization

    @distribution.transaction do
      @distribution.destroy!
      @distribution.storage_location.increase_inventory(@distribution)
    end
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "[!] DistributionsController#destroy failed to destroy distribution #{@distribution_id} because it does not exist"
    @error = e
  rescue Errors::InsufficientAllotment => e
    @distribution.line_items.assign_insufficiency_errors(e.insufficient_items)
    Rails.logger.error "[!] DistributionsController#destroy failed because of Insufficient Allotment #{@organization.short_name}: #{@distribution.errors.full_messages} [#{e.message}]"
    @error = e
  rescue StandardError => e
    Rails.logger.error "[!] DistributionsController#destroy failed to destroy distribution for #{@distribution.organization.short_name}: #{@distribution.errors.full_messages} [#{e.inspect}]"
    @error = e
  ensure
    return self
  end

  def success?
    @error.nil?
  end
end

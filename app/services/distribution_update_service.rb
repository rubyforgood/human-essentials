class DistributionUpdateService
  attr_reader :distribution, :error

  def initialize(old_distribution, new_distribution_params)
    @distribution = old_distribution
    @params = new_distribution_params
    @organization = @distribution.organization
    @error = nil
  end

  # FIXME: This doesn't allow for the storage location to be changed.
  def call
    @distribution.transaction do
      @old_issued_at = @distribution.issued_at
      @distribution.storage_location.increase_inventory(@distribution.to_a)

      # Delete the line items -- they'll be replaced later
      @distribution.line_items.each(&:destroy!)
      @distribution.reload
      # Replace the current distribution with the new parameters
      @distribution.update! @params
      @distribution.reload
      @new_issued_at = @distribution.issued_at
      # Apply the new changes to the storage location inventory
      @distribution.storage_location.decrease_inventory(@distribution.to_a)
    end
  rescue Errors::InsufficientAllotment => e
    @distribution.line_items.assign_insufficiency_errors(e.insufficient_items)
    Rails.logger.error "[!] DistributionsController#update failed because of Insufficient Allotment #{@organization.short_name}: #{@distribution.errors.full_messages} [#{e.message}]"
    @error = e
  rescue StandardError => e
    Rails.logger.error "[!] DistributionsController#update failed to update distribution for #{@distribution.organization.short_name}: #{@distribution.errors.full_messages} [#{e.inspect}]"
  ensure
    return self
  end

  def success?
    @error.nil?
  end

  def resend_notification?
    @old_issued_at.to_date != @new_issued_at.to_date
  end
end

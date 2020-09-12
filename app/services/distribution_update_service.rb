class DistributionUpdateService < DistributionService
  def initialize(old_distribution, new_distribution_params)
    @distribution = old_distribution
    @params = new_distribution_params
  end

  # FIXME: This doesn't allow for the storage location to be changed.
  def call
    perform_distribution_service do
      @old_issued_at = distribution.issued_at
      @old_delivery_method = distribution.delivery_method
      distribution.storage_location.increase_inventory(distribution.to_a)
      # Delete the line items -- they'll be replaced later
      distribution.line_items.each(&:destroy!)
      distribution.reload
      # Replace the current distribution with the new parameters
      distribution.update! @params
      distribution.reload
      @new_issued_at = distribution.issued_at
      @new_delivery_method = distribution.delivery_method
      # Apply the new changes to the storage location inventory
      distribution.storage_location.decrease_inventory(distribution.to_a)
    end
  end

  def resend_notification?
    issued_at_changed? || delivery_method_changed?
  end

  def issued_at_changed?
    @old_issued_at.to_date != @new_issued_at.to_date
  end

  def delivery_method_changed?
    @old_delivery_method != @new_delivery_method
  end
end

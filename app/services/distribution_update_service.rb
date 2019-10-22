class DistributionUpdateService
  def initialize(old_distribution, new_distribution_params)
    @distribution = old_distribution
    @params = new_distribution_params
  end

  def call
    @distribution.transaction do
      old_issued_at = @distribution.issued_at
      @distribution.storage_location.increase_inventory(@distribution.to_a)

      # Delete the line items -- they'll be replaced later
      @distribution.line_items.each(&:destroy!)
      @distribution.reload

      # Replace the current distribution with the new parameters
      @distribution.update! @params
      @distribution.reload
      new_issued_at = @distribution.issued_at
      # Apply the new changes to the storage location inventory
      @distribution.storage_location.decrease_inventory(@distribution.to_a)
      OpenStruct.new(success?: true, distribution: @distribution,
                     resend_notification?: resend_notification?(old_issued_at, new_issued_at))
    end
  rescue StandardError => e
    Rails.logger.error "[!] DistributionsController#update failed to update distribution for #{@distribution.organization.short_name}: #{@distribution.errors.full_messages} [#{e.inspect}]"
    OpenStruct.new(success: false, distribution: @distribution, error: e)
  end

  private

  def resend_notification?(old_issued_at, new_issued_at)
    old_issued_at.to_date != new_issued_at.to_date
  end
end

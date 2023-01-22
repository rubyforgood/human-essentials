class DistributionService
  attr_reader :error

  def perform_distribution_service(&block)
    distribution.transaction do
      yield block
    end
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "[!] #{self.class.name} failed to destroy distribution #{distribution_id} because it does not exist"
    set_error(e)
  rescue Errors::InsufficientAllotment => e
    distribution.line_items.assign_insufficiency_errors(e.insufficient_items)
    Rails.logger.error "[!] #{self.class.name} failed because of Insufficient Allotment #{distribution_organization.short_name}: #{distribution.errors.full_messages} [#{e.message}]"
    set_error(e)
  rescue StandardError => e
    Rails.logger.error "[!] #{self.class.name} failed for #{distribution_organization.short_name}: #{distribution.errors.full_messages} [#{e.inspect}]"
    set_error(e)
  ensure
    return self
  end

  def success?
    error.nil?
  end

  private

  def distribution_organization
    @distribution_organization ||= distribution&.organization
  end

  def set_error(error)
    @error = error
  end

  def distribution
    # Return distribution if it has already been defined
    return @distribution if @distribution

    # Otherwise try to get this value with possibly
    # provided distribution_id from initialize
    if @distribution_id.present?
      @distribution = Distribution.find(@distribution_id)
    end
  end

  def distribution_id
    return @distribution_id if @distribution_id

    if distribution.present?
      @distribution_id = distribution.id
    end
  end
end


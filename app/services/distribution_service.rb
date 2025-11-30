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
    Rails.logger.error "[!] #{self.class.name} failed because of Insufficient Allotment #{distribution_organization.name}: #{distribution.errors.full_messages} [#{e.message}]"
    set_error(e)
  rescue StandardError => e
    Rails.logger.error "[!] #{self.class.name} failed for #{distribution_organization.name}: #{distribution.errors.full_messages} [#{e.inspect}]"
    set_error(e)
  ensure
    return self
  end

  def distribution
    # Return distribution if it has already been defined
    return @distribution if instance_variable_defined? :@distribution

    # Otherwise try to get this value with possibly
    # provided distribution_id from initialize
    @distribution = @distribution_id.present? ? Distribution.find(@distribution_id) : nil
  end

  def success?
    error.nil?
  end

  private

  def distribution_organization
    return @distribution_organization if instance_variable_defined? :@distribution_organization

    @distribution_organization = distribution&.organization
  end

  def set_error(error)
    @error = error
  end

  def distribution_id
    return @distribution_id if instance_variable_defined? :@distribution_id

    @distribution_id = distribution&.id
  end
end


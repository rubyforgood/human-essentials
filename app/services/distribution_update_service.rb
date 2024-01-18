class DistributionUpdateService < DistributionService
  def initialize(old_distribution, new_distribution_params)
    @distribution = old_distribution
    @params = new_distribution_params
    @old_line_items = old_distribution.line_item_values
  end

  def call
    perform_distribution_service do
      @old_issued_at = distribution.issued_at
      @old_delivery_method = distribution.delivery_method

      ItemizableUpdateService.call(
        itemizable: distribution,
        params: @params,
        type: :decrease,
        event_class: DistributionEvent
      )

      @new_issued_at = distribution.issued_at
      @new_delivery_method = distribution.delivery_method
    end
  end

  def resend_notification?
    issued_at_changed? || delivery_method_changed? || distribution_content.any_change?
  end

  def distribution_content
    @distribution_content ||= DistributionContentChangeService.new(@old_line_items, distribution.line_item_values).call
  end

  private

  def issued_at_changed?
    @old_issued_at.to_date != @new_issued_at.to_date
  end

  def delivery_method_changed?
    @old_delivery_method != @new_delivery_method
  end
end

module AdjustmentCreateService
  def self.call(adjustment)
    adjustment.save && AdjustmentEvent.publish(adjustment)
  end
end

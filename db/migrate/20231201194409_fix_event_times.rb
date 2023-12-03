class FixEventTimes < ActiveRecord::Migration[7.0]
  def change
    Event.where(type: %i(DistributionEvent DonationEvent PurchaseEvent)).find_each do |event|
      next if event.eventable.nil?

      event.update_attribute(:event_time, event.eventable.created_at)
    end
  end
end

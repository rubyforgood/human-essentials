class FixInvalidDistributionEvent20241112 < ActiveRecord::Migration[7.1]
  def change
    return unless Rails.env.production?

    # We are not sure why yet, but this org was able to create a distribution
    # that put them at a negative inventory. Later playback of the events with
    # validation turned on then raised it as an error. For now we are deleting
    # the distribution and event directly.
    Event.where(id: 42075, eventable_type: 'Distribution', eventable_id: 789204).first.destroy
    Distribution.find(789204).destroy
  end
end

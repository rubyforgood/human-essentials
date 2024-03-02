class UpdateEventTimes < ActiveRecord::Migration[7.0]
  def change
    Event.update_all('event_time=created_at')
  end
end

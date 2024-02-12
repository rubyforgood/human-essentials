class FixDestroyEvents < ActiveRecord::Migration[7.0]
  def change
    TransferDestroyEvent.all.each do |event|
      event.update!(event_time: event.eventable.created_at) if event.eventable
    end
  end
end

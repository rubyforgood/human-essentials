class RemoveExcessKitVillageDiaperBank < ActiveRecord::Migration[7.1]
  def change
    return unless Rails.env.production?
    Kit.find(204).destroy
  end
end

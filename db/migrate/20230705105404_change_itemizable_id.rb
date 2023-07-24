class ChangeItemizableId < ActiveRecord::Migration[7.0]
  def change
    Rake::Task['change_itemizable_id'].invoke
  end
end

class AddCommentToDonations < ActiveRecord::Migration[5.0]
  def change
    add_column :donations, :comment, :text
  end
end

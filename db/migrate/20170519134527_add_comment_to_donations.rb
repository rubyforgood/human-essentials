# Stakeholder wanted to provide context on incoming donations
class AddCommentToDonations < ActiveRecord::Migration[5.0]
  def change
    add_column :donations, :comment, :text
  end
end

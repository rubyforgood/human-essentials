# Users can now send feedback about bugs, features, etc directly to the devs
class AddFeedbackMessage < ActiveRecord::Migration[5.2]
  def change

    create_table :feedback_messages do |t|
      t.belongs_to :user, index: true
      t.string :message
      t.string :path
      t.timestamps
    end
  end
end

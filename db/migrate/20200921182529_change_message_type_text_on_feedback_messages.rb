class ChangeMessageTypeTextOnFeedbackMessages < ActiveRecord::Migration[6.0]
  def change
    reversible do |dir|
      dir.up do
        change_column :feedback_messages, :message, :text
      end
      dir.down do
        change_column :feedback_messages, :message, :string
      end
    end
  end
end

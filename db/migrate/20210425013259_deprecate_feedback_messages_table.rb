class DeprecateFeedbackMessagesTable < ActiveRecord::Migration[6.0]
  def change
    safety_assured do
      rename_table :feedback_messages, :deprecated_feedback_messages
    end
  end
end

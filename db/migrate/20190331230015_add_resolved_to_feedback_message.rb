# Now we can track when an issue in our backlog has been addressed
class AddResolvedToFeedbackMessage < ActiveRecord::Migration[5.2]
  def change
    add_column :feedback_messages, :resolved, :boolean
  end
end

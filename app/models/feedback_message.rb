class FeedbackMessage
  include ActiveModel::Model
  attr_accessor :user_name, :user_id, :user_email, :path, :timestamp, :message
end

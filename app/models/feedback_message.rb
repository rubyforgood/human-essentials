# == Schema Information
#
# Table name: feedback_messages
#
#  id         :bigint           not null, primary key
#  message    :string
#  path       :string
#  resolved   :boolean
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :bigint
#

class FeedbackMessage < ApplicationRecord
  belongs_to :user
end

# == Schema Information
#
# Table name: feedback_messages
#
#  id         :bigint(8)        not null, primary key
#  user_id    :bigint(8)
#  message    :string
#  path       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  resolved   :boolean
#

class FeedbackMessage < ApplicationRecord
  belongs_to :user
end

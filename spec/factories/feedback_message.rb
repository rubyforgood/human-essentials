FactoryBot.define do
  factory :feedback_message do
    message { "Feedback message that has been left." }
    path { "https://example.com/diaperbank/dashboard" }
    user { User.try(:first) || create(:user) }
    resolved { false }
  end
end
#
#  id         :bigint(8)        not null, primary key
#  user_id    :bigint(8)
#  message    :string
#  path       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

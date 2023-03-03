FactoryBot.define do
  factory :broadcast_announcement do
    user
    organization
    message { "test" }
  end
end

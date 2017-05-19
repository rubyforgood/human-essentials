# == Schema Information
#
# Table name: transfers
#
#  id         :integer          not null, primary key
#  from_id    :integer
#  to_id      :integer
#  comment    :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

FactoryGirl.define do
  factory :transfer do
    from_id { create(:storage_location).id }
    to_id { create(:storage_location).id }
    comment "A comment"
  end
end

# == Schema Information
#
# Table name: organizations
#
#  id         :integer          not null, primary key
#  name       :string
#  short_name :string
#  address    :text
#  email      :string
#  url        :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

FactoryGirl.define do

  factory :organization do
    sequence(:name) { |n| "Diaper Bank #{n}" } # 037000863427
    sequence(:short_name) { |n| "db_#{n}" } # 037000863427
  end

end

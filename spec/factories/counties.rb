# == Schema Information
#
# Table name: counties
#
#  id         :bigint           not null, primary key
#  name       :string
#  region     :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
FactoryBot.define do
  factory :county do
    county { "MyString" }
    string { "MyString" }
    state_or_territory { "MyString" }
    string { "MyString" }
  end
end

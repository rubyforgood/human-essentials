# == Schema Information
#
# Table name: tags
#
#  id         :bigint           not null, primary key
#  name       :string(256)      not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
FactoryBot.define do
  factory :tag do
    name { "Holidays" }
    initialize_with { Tag.find_or_create_by(name:) }
  end
end

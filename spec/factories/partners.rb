# == Schema Information
#
# Table name: partners
#
#  id         :integer          not null, primary key
#  name       :string
#  email      :string
#  created_at :datetime
#  updated_at :datetime
#

FactoryGirl.define do
  factory :partner do
    name "Leslie Sue"
    email "leslie@gmail.com"
  end
end

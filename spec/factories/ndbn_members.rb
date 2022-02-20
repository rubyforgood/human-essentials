# == Schema Information
#
# Table name: ndbn_members
#
#  account_name   :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  ndbn_member_id :bigint           not null, primary key
#
FactoryBot.define do
  factory :ndbn_member, class: NDBNMember do
    ndbn_member_id { 1 }
    account_name { "MyString" }
  end
end

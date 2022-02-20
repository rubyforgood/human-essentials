# == Schema Information
#
# Table name: ndbn_members
#
#  account_name   :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  ndbn_member_id :bigint           not null, primary key
#
class NDBNMember < ApplicationRecord
  self.primary_key = "ndbn_member_id"

  validates_presence_of :ndbn_member_id
  validates_presence_of :account_name
  validates_uniqueness_of :ndbn_member_id
end

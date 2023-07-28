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
  has_paper_trail
  self.primary_key = "ndbn_member_id"

  validates :ndbn_member_id, presence: true
  validates :account_name, presence: true
  validates :ndbn_member_id, uniqueness: true

  def full_name
    "#{ndbn_member_id} - #{account_name}"
  end
end

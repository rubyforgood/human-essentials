# == Schema Information
#
# Table name: partner_group_items
#
#  id               :bigint           not null, primary key
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  item_id          :bigint           not null
#  partner_group_id :bigint           not null
#
class PartnerGroupItem < ApplicationRecord
  belongs_to :partner_group
  belongs_to :item
end

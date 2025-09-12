# == Schema Information
#
# Table name: item_units
#
#  id            :bigint           not null, primary key
#  name          :string           not null
#  request_limit :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  item_id       :bigint
#
class ItemUnit < ApplicationRecord
  belongs_to :item

  validate do
    names = item.organization.request_units.map(&:name)
    unless names.include?(name)
      errors.add(:name, "is not supported by the organization")
    end
  end
end

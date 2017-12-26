# == Schema Information
#
# Table name: barcode_items
#
#  id              :integer          not null, primary key
#  value           :string
#  item_id         :integer
#  quantity        :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :integer
#

class BarcodeItem < ApplicationRecord
  belongs_to :organization, optional: true
  belongs_to :item, dependent: :destroy, counter_cache: :barcode_count

  validates :value, presence: true, uniqueness: true
  validates :quantity, :item, presence: true
  validates :quantity, numericality: { only_integer: true, greater_than_or_equal_to: 0}

  # Virtual Attribute for "global" to make it play nice with
  # forms. There might be a cleaner way to do this -- please
  # refactor if this VA dirtiness is spilling over into other
  # features or it's causing code distortion.
  def global
    # If this is a totally new record, we want to default to `false`
    id.present? && organization_id.nil?
  end

  def global=(boolean_make_global)
    organization_id = nil if boolean_make_global
  end

  include Filterable
  scope :item_id, ->(item_id) { where(item_id: item_id) }

  # TODO - this should be renamed to something more specific -- it produces a hash, not a line_item object
  def to_h
    {
      item_id: item.id,
      quantity: quantity
    }
  end
end

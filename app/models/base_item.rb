# == Schema Information
#
# Table name: base_items
#
#  id            :bigint           not null, primary key
#  barcode_count :integer
#  category      :string
#  item_count    :integer
#  name          :string
#  partner_key   :string
#  size          :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

class BaseItem < ApplicationRecord
  has_paper_trail
  has_many :items, dependent: :destroy, inverse_of: :base_item, foreign_key: :partner_key, primary_key: :partner_key
  has_many :barcode_items, as: :barcodeable, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :partner_key, presence: true, uniqueness: true

  scope :by_partner_key, ->(partner_key) { where(partner_key: partner_key) }
  scope :without_kit, -> { where.not(name: 'Kit') }
  scope :alphabetized, -> { order(:name) }

  def to_h
    { partner_key: partner_key, name: name }
  end

  def self.seed_items
    base_items = File.read(Rails.root.join("db", "base_items.json"))
    items_by_category = JSON.parse(base_items)
    base_items_data = items_by_category.map do |category, entries|
      entries.map do |entry|
        {
          name: entry["name"],
          category: category,
          partner_key: entry["key"],
          updated_at: Time.zone.now,
          created_at: Time.zone.now
        }
      end
    end.flatten

    BaseItem.create!(base_items_data)
  end
end


# == Schema Information
#
# Table name: items
#
#  id                           :integer          not null, primary key
#  active                       :boolean          default(TRUE)
#  additional_info              :text
#  barcode_count                :integer
#  distribution_quantity        :integer
#  name                         :string
#  on_hand_minimum_quantity     :integer          default(0), not null
#  on_hand_recommended_quantity :integer
#  package_size                 :integer
#  partner_key                  :string
#  reporting_category           :string
#  value_in_cents               :integer          default(0)
#  visible_to_partners          :boolean          default(TRUE), not null
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  item_category_id             :integer
#  kit_id                       :integer
#  organization_id              :integer
#

class Item < ApplicationRecord
  has_paper_trail
  include Filterable
  include Exportable
  include Valuable

  after_initialize :set_default_distribution_quantity, if: :new_record?
  after_update :update_associated_kit_name, if: -> { kit.present? }
  before_destroy :validate_destroy, prepend: true

  belongs_to :organization # If these are universal this isn't necessary
  belongs_to :base_item, counter_cache: :item_count, primary_key: :partner_key, foreign_key: :partner_key, inverse_of: :items, optional: true
  belongs_to :kit, optional: true
  belongs_to :item_category, optional: true

  validates :additional_info, length: { maximum: 500 }
  validates :name, uniqueness: { scope: :organization, case_sensitive: false, message: "- An item with that name already exists (could be an inactive item)" }
  validates :name, presence: true
  validates :distribution_quantity, numericality: { greater_than: 0 }, allow_blank: true
  validates :on_hand_recommended_quantity, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true
  validates :on_hand_minimum_quantity, numericality: { greater_than_or_equal_to: 0 }
  validates :package_size, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true
  validates :reporting_category, presence: true, unless: proc { |i| i.kit }

  has_many :line_items, dependent: :destroy
  has_many :inventory_items, dependent: :destroy
  has_many :barcode_items, as: :barcodeable, dependent: :destroy
  has_many :donations, through: :line_items, source: :itemizable, source_type: "::Donation"
  has_many :distributions, through: :line_items, source: :itemizable, source_type: "::Distribution"
  has_many :request_units, class_name: "ItemUnit", dependent: :destroy

  scope :active, -> { where(active: true) }

  # :housing_a_kit are items which house a kit, NOT items is_in_kit
  scope :housing_a_kit, -> { where.not(kit_id: nil) }
  scope :loose, -> { where(kit_id: nil) }
  scope :inactive, -> { where.not(active: true) }

  scope :visible, -> { where(visible_to_partners: true) }
  scope :alphabetized, -> { order(:name) }
  scope :by_base_item, ->(base_item) { where(base_item: base_item) }
  scope :by_reporting_category, ->(reporting_category) { where(reporting_category: reporting_category) }
  scope :by_partner_key, ->(partner_key) { where(partner_key: partner_key) }

  scope :period_supplies, -> {
    where(reporting_category: [:pads, :tampons, :period_liners, :period_underwear, :period_other])
  }

  enum :reporting_category, {
    adult_incontinence: "adult_incontinence",
    cloth_diapers: "cloth_diapers",
    disposable_diapers: "disposable_diapers",
    pads: "pads",
    period_liners: "period_liners",
    period_other: "period_other",
    period_underwear: "period_underwear",
    tampons: "tampons",
    other_categories: "other"
  }, instance_methods: false, validate: { allow_nil: true }

  def self.reporting_categories_for_select
    reporting_categories.map do |key, value|
      Option.new(id: key, name: value.titleize)
    end
  end

  def self.reactivate(item_ids)
    item_ids = Array.wrap(item_ids)
    Item.where(id: item_ids).find_each { |item| item.update(active: true) }
  end

  def has_inventory?(inventory = nil)
    inventory&.quantity_for(item_id: id)&.positive?
  end

  def in_request?
    Request.by_request_item_id(id).exists?
  end

  def is_in_kit?(kits = nil)
    if kits
      kits.any? { |k| k.line_items.map(&:item_id).include?(id) }
    else
      organization.kits
        .active
        .joins(:line_items)
        .where(line_items: { item_id: id}).any?
    end
  end

  def can_delete?(inventory = nil, kits = nil)
    can_deactivate_or_delete?(inventory, kits) && line_items.none? && !barcode_count&.positive? && !in_request? && kit.blank?
  end

  # @return [Boolean]
  def can_deactivate_or_delete?(inventory = nil, kits = nil)
    inventory ||= View::Inventory.new(organization_id)
    # Cannot deactivate if it's currently in inventory in a storage location. It doesn't make sense
    # to have physical inventory of something we're now saying isn't valid.
    # If an active kit includes this item, then changing kit allocations would change inventory
    # for an inactive item - which we said above we don't want to allow.

    !has_inventory?(inventory) && !is_in_kit?(kits)
  end

  def validate_destroy
    unless can_delete?
      errors.add(:base, "Cannot delete item - it has already been used!")
      throw(:abort)
    end
  end

  def deactivate!
    unless can_deactivate_or_delete?
      raise "Cannot deactivate item - it is in a storage location or kit!"
    end
    if kit
      kit.deactivate
    else
      update!(active: false)
    end
  end

  # @return [String]
  def reporting_category_humanized
    Item.reporting_categories[reporting_category].to_s.titleize
  end

  def other?
    partner_key == "other"
  end

  # Convenience method so that other methods can be simplified to
  # expect an id or an Item object
  def to_i
    id
  end

  def to_h
    { name: name, item_id: id }
  end

  def self.csv_export_headers
    ["Name", "Barcodes", "Quantity"]
  end

  # @param items [Array<Item>]
  # @param inventory [View::Inventory]
  # @return [String]
  def self.generate_csv_from_inventory(items, inventory)
    item_quantities = items.to_h { |i| [i.id, inventory.quantity_for(item_id: i.id)] }
    CSV.generate(headers: true) do |csv|
      csv_data = items.map do |item|
        attributes = [item.name, item.barcode_count, item_quantities[item.id]]
        attributes.map { |attr| normalize_csv_attribute(attr) }
      end
      ([csv_export_headers] + csv_data).each { |row| csv << row }
    end
  end

  def default_quantity
    distribution_quantity || 50
  end

  def sync_request_units!(unit_ids)
    request_units.clear
    organization.request_units.where(id: unit_ids).pluck(:name).each do |name|
      request_units.create!(name:)
    end
  end

  private

  def set_default_distribution_quantity
    self.distribution_quantity ||= kit_id.present? ? 1 : 50
  end

  def update_associated_kit_name
    kit.update(name: name)
  end
end

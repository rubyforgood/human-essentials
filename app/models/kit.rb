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
#  type                         :string           default("ConcreteItem"), not null
#  value_in_cents               :integer          default(0)
#  visible_to_partners          :boolean          default(TRUE), not null
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  item_category_id             :integer
#  kit_id                       :integer
#  organization_id              :integer
#
class Kit < Item
  scope :by_name, ->(name) { where("name ILIKE ?", "%#{name}%") }

  # Kits are managed through the kits UI (deactivate/reactivate), not the normal
  # item-deletion path.
  def can_delete?(inventory = nil, kits = nil)
    false
  end

  # Kits can't reactivate if they have any inactive items, because now whenever they are allocated
  # or deallocated, we are changing inventory for inactive items (which we don't allow).
  # @return [Boolean]
  def can_reactivate?
    line_items.joins(:item).where(items: {active: false}).none?
  end

  def reactivate
    update!(active: true)
  end

  private

  # Kits default to a distribution quantity of 1 (a single kit), not 50.
  def default_distribution_quantity
    1
  end
end

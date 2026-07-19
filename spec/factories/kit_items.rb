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
FactoryBot.define do
  factory :kit_item do
    sequence(:name) { |n| "#{n} - Dont test this" }
    partner_key { nil }
    reporting_category { kit ? nil : "disposable_diapers" }
    organization

    # Once we start using this directly, we should start adding line items by default same as kit
    # after(:build) do |instance, _|
    #   if instance.line_items.blank?
    #     instance.line_items << build(:line_item, item: create(:item, organization: instance.organization), itemizable: nil)
    #   end
    # end
  end
end

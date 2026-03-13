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

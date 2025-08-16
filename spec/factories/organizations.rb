# == Schema Information
#
# Table name: organizations
#
#  id                                       :integer          not null, primary key
#  bank_is_set_up                           :boolean          default(FALSE), not null
#  city                                     :string
#  deadline_day                             :integer
#  default_storage_location                 :integer
#  distribute_monthly                       :boolean          default(FALSE), not null
#  email                                    :string
#  enable_child_based_requests              :boolean          default(TRUE), not null
#  enable_individual_requests               :boolean          default(TRUE), not null
#  enable_quantity_based_requests           :boolean          default(TRUE), not null
#  hide_package_column_on_receipt           :boolean          default(FALSE)
#  hide_value_columns_on_receipt            :boolean          default(FALSE)
#  include_in_kind_values_in_exported_files :boolean          default(FALSE), not null
#  intake_location                          :integer
#  invitation_text                          :text
#  latitude                                 :float
#  longitude                                :float
#  name                                     :string
#  one_step_partner_invite                  :boolean          default(FALSE), not null
#  partner_form_fields                      :text             default([]), is an Array
#  receive_email_on_requests                :boolean          default(FALSE), not null
#  reminder_day                             :integer
#  repackage_essentials                     :boolean          default(FALSE), not null
#  signature_for_distribution_pdf           :boolean          default(FALSE)
#  state                                    :string
#  street                                   :string
#  url                                      :string
#  ytd_on_distribution_printout             :boolean          default(TRUE), not null
#  zipcode                                  :string
#  created_at                               :datetime         not null
#  updated_at                               :datetime         not null
#  account_request_id                       :integer
#  ndbn_member_id                           :bigint
#
require 'seeds'

FactoryBot.define do
  factory :organization do
    sequence(:name) { |n| "Dont test this name #{n}" } # 037000863427

    trait :with_items do
      after(:create) do |instance, evaluator|
        Seeds.seed_base_items if BaseItem.count.zero? # seeds 45 base items if none exist
        Organization.seed_items(instance) # creates 1 item for each base item
      end
    end
  end
end

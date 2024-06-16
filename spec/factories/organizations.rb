# == Schema Information
#
# Table name: organizations
#
#  id                             :integer          not null, primary key
#  city                           :string
#  deadline_day                   :integer
#  default_storage_location       :integer
#  distribute_monthly             :boolean          default(FALSE), not null
#  email                          :string
#  enable_child_based_requests    :boolean          default(TRUE), not null
#  enable_individual_requests     :boolean          default(TRUE), not null
#  enable_quantity_based_requests :boolean          default(TRUE), not null
#  hide_package_column_on_receipt :boolean          default(FALSE)
#  hide_value_columns_on_receipt  :boolean          default(FALSE)
#  intake_location                :integer
#  invitation_text                :text
#  latitude                       :float
#  longitude                      :float
#  name                           :string
#  one_step_partner_invite        :boolean          default(FALSE), not null
#  partner_form_fields            :text             default([]), is an Array
#  reminder_day                   :integer
#  repackage_essentials           :boolean          default(FALSE), not null
#  short_name                     :string
#  signature_for_distribution_pdf :boolean          default(FALSE)
#  state                          :string
#  street                         :string
#  url                            :string
#  ytd_on_distribution_printout   :boolean          default(TRUE), not null
#  zipcode                        :string
#  created_at                     :datetime         not null
#  updated_at                     :datetime         not null
#  account_request_id             :integer
#  ndbn_member_id                 :bigint
#

FactoryBot.define do
  factory :organization do
    transient do
      skip_items { false }
    end

    sequence(:name) { |n| "Essentials Bank #{n}" } # 037000863427
    sequence(:short_name) { |n| "db_#{n}" } # 037000863427
    sequence(:email) { |n| "email#{n}@example.com" } # 037000863427
    sequence(:url) { |n| "https://organization#{n}.org" } # 037000863427
    street { "1500 Remount Road" }
    city { 'Front Royal' }
    state { 'VA' }
    zipcode { '22630' }
    reminder_day { 10 }
    deadline_day { 20 }

    logo { Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/logo.jpg"), "image/jpeg") }

    trait :without_deadlines do
      reminder_day { nil }
      deadline_day { nil }
    end

    trait :with_items do
      after(:create) do |instance, evaluator|
        seed_base_items if BaseItem.count.zero? # seeds 45 base items if none exist
        Organization.seed_items(instance) # creates 1 item for each base item
      end
    end
  end
end

# == Schema Information
#
# Table name: organizations
#
#  id                :integer          not null, primary key
#  name              :string
#  short_name        :string
#  address           :text
#  email             :string
#  url               :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  logo_file_name    :string
#  logo_content_type :string
#  logo_file_size    :integer
#  logo_updated_at   :datetime
#  intake_location   :integer
#  street            :string
#  city              :string
#  state             :string
#  zipcode           :string
#

FactoryBot.define do

  factory :organization do
    sequence(:name) { |n| "Diaper Bank #{n}" } # 037000863427
    sequence(:short_name) { |n| "db_#{n}" } # 037000863427
    sequence(:email) { |n| "email#{n}@example.com" } # 037000863427
    sequence(:url) { |n| "https://organization#{n}.org" } # 037000863427

    logo { Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/logo.jpg'), 'image/jpeg') }
  end

end

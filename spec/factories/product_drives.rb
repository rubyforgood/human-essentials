# == Schema Information
#
# Table name: product_drives
#
#  id              :bigint           not null, primary key
#  end_date        :date
#  name            :string
#  start_date      :date
#  virtual         :boolean          default(FALSE), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :bigint
#
FactoryBot.define do
  factory :product_drive do
    name { "Test Drive" }
    start_date { Time.current }
    end_date { Time.current }
    virtual { [true, false].sample }
    organization { Organization.try(:first) || create(:organization) }
  end
end

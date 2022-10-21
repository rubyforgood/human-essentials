# == Schema Information
#
# Table name: partner_counties
#
#  id           :bigint           not null, primary key
#  client_share :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  county_id    :bigint           not null
#  partner_id   :bigint           not null
#
require 'rails_helper'

RSpec.describe PartnerCounty, type: :model do

  context "Validations >" do
    it "must belong to a partner" do
      expect(build(:partner_county, county: create(:county), partner_id: nil, client_share: 0)).not_to be_valid
    end
    it "must belong to a county" do
      expect(build(:partner_county, partner: create(:partner), county_id: nil, client_share: 0)).not_to be_valid
    end
  end
end

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

  it { should belong_to(:partner) }
  it { should belong_to(:county) }


  it "must only allow integer client shares" do
    expect(build(:partner_county, partner: create(:partner), county: create(:county), client_share: 50)).to be_valid
    expect(build(:partner_county, partner: create(:partner), county: create(:county), client_share: 50.5)).not_to be_valid
  end
  it "must only allow valid client share values" do
    expect(build(:partner_county, partner: create(:partner), county: create(:county), client_share: 0)).not_to be_valid
    expect(build(:partner_county, partner: create(:partner), county: create(:county), client_share: 101)).not_to be_valid
    expect(build(:partner_county, partner: create(:partner), county: create(:county), client_share: 1)).to be_valid
    expect(build(:partner_county, partner: create(:partner), county: create(:county), client_share: 100)).to be_valid
  end


end

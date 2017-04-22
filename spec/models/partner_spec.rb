# == Schema Information
#
# Table name: partners
#
#  id         :integer          not null, primary key
#  name       :string
#  email      :string
#  created_at :datetime
#  updated_at :datetime
#

require "rails_helper"

RSpec.describe Partner, type: :model do
  it "has a name" do
    partner = FactoryGirl.create :partner
    expect(partner.name).to_not be nil
  end

  it "has an email address" do
    partner = FactoryGirl.create :partner
    expect(partner.email).to_not be nil
  end

  it "has many tickets" do
    assc = described_class.reflect_on_association(:tickets)
    expect(assc.macro).to eq :has_many
  end

end

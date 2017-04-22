# == Schema Information
#
# Table name: items
#
#  id         :integer          not null, primary key
#  name       :string
#  category   :string
#  created_at :datetime
#  updated_at :datetime
#

require "rails_helper"

RSpec.describe Item, type: :model do
  it "has a name" do
    item = Item.create(name: "Diaper")
    expect(item.name).to_not be nil
  end

  it "has many containers" do
    assc = described_class.reflect_on_association(:containers)
    expect(assc.macro).to eq :has_many
  end

  it "has many holdings" do
    assc = described_class.reflect_on_association(:holdings)
    expect(assc.macro).to eq :has_many
  end

  it "has many donations" do
    assc = described_class.reflect_on_association(:donations)
    expect(assc.macro).to eq :has_many
  end

  it "has many tickets" do
    assc = described_class.reflect_on_association(:tickets)
    expect(assc.macro).to eq :has_many
  end
end

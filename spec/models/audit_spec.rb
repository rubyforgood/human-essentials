# == Schema Information
#
# Table name: audits
#
#  id                  :bigint           not null, primary key
#  status              :integer          default("in_progress"), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  adjustment_id       :bigint
#  organization_id     :bigint
#  storage_location_id :bigint
#  user_id             :bigint
#

require 'rails_helper'

RSpec.describe Audit, type: :model do
  it_behaves_like "itemizable"

  context "Validations >" do
    it "must belong to an organization" do
      expect(build(:audit, storage_location: create(:storage_location), organization_id: nil)).not_to be_valid
      expect(build(:audit, organization: @organization)).to be_valid
    end

    it "must belong to an organization admin of its organization" do
      expect(build(:audit, storage_location: create(:storage_location, organization: @organization), user: @user, organization: @organization)).not_to be_valid
      expect(build(:audit, storage_location: create(:storage_location, organization: @organization), user: @organization_admin,  organization: @organization)).to be_valid
    end

    it "can not have line items that has quantity as a negative integer" do
      item = create(:item)
      storage_location = create(:storage_location, :with_items, item: item, item_quantity: 10)
      audit = build(:audit,
                    storage_location: storage_location,
                    line_items_attributes: [
                      { item_id: storage_location.items.first.id, quantity: -10 }
                    ])

      expect(audit.save).to be_falsey
    end

    it "can not have line items that has quantity as zero" do
      item = create(:item)
      storage_location = create(:storage_location, :with_items, item: item, item_quantity: 10)
      audit = build(:audit,
                    storage_location: storage_location,
                    line_items_attributes: [
                      { item_id: storage_location.items.first.id, quantity: 0 }
                    ])

      expect(audit.save).to be_falsey
    end

    it "can not have line items that has quantity as a string that cannot be reduced to an integer" do
      item = create(:item)
      storage_location = create(:storage_location, :with_items, item: item, item_quantity: 10)
      audit = build(:audit,
                    storage_location: storage_location,
                    line_items_attributes: [
                      { item_id: storage_location.items.first.id, quantity: "three" }
                    ])

      expect(audit.save).to be_falsey
    end

    it "can have line items that has quantity as a positive integer" do
      item = create(:item)
      storage_location = create(:storage_location, :with_items, item: item, item_quantity: 10)
      audit = build(:audit,
                    storage_location: storage_location,
                    line_items_attributes: [
                      { item_id: storage_location.items.first.id, quantity: 10 }
                    ])

      expect(audit.save).to be_truthy
    end
  end

  context "Scopes >" do
    it "`at_location` can filter out audits to a specific location" do
      audit1 = create(:audit)
      create(:audit)
      expect(Audit.at_location(audit1.storage_location_id).size).to eq(1)
    end
  end

  context "Methods >" do
    it "`self.storage_locations_audited_for` returns only storage_locations that are used for one org" do
      storage_location1 = create(:storage_location, organization: @organization)
      storage_location2 = create(:storage_location, organization: @organization)
      create(:storage_location, organization: @organization)
      storage_location4 = create(:storage_location, organization: create(:organization))
      create(:audit, storage_location: storage_location1, organization: @organization)
      create(:audit, storage_location: storage_location2, organization: @organization)
      create(:audit, storage_location: storage_location4, organization: storage_location4.organization)
      expect(Audit.storage_locations_audited_for(@organization).to_a).to match_array([storage_location1, storage_location2])
    end
  end
end

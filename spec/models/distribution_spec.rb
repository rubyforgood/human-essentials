# == Schema Information
#
# Table name: distributions
#
#  id                  :bigint(8)        not null, primary key
#  comment             :text
#  created_at          :datetime
#  updated_at          :datetime
#  storage_location_id :integer
#  partner_id          :integer
#  organization_id     :integer
#  issued_at           :datetime
#  agency_rep          :string
#

RSpec.describe Distribution, type: :model do
  it_behaves_like "itemizable"

  context "Validations >" do
    it "must belong to an organization" do
      expect(build(:distribution, organization: nil)).not_to be_valid
    end
    it "requires a storage location" do
      expect(build(:distribution, storage_location: nil)).not_to be_valid
    end

    it "requires a partner" do
      expect(build(:distribution, partner: nil)).not_to be_valid
    end

    it "ensures the associated line_items are valid" do
      d = build(:distribution)
      d.line_items << build(:line_item, quantity: nil)
      expect(d).not_to be_valid
    end

    it "ensures that any included items are found in the associated storage location" do
      d = build(:distribution)
      item_missing = create(:item, name: "missing")
      d.line_items << build(:line_item, item: item_missing)
      expect(d).not_to be_valid
    end
  end

  context "Scopes >" do
    describe "during >" do
      it "returns all distrbutions created between two dates" do
        Distribution.destroy_all
        # The models should default to assigning the created_at time to the issued_at
        create(:distribution, created_at: Date.today)
        # but just for fun we'll force one in the past within the range
        create(:distribution, issued_at: Date.yesterday)
        # and one outside the range
        create(:distribution, issued_at: 1.year.ago)
        expect(Distribution.during(1.month.ago..Date.tomorrow).size).to eq(2)
      end
    end
  end

  context "Callbacks >" do
    it "initializes the issued_at field to default to created_at if it wasn't explicitly set" do
      yesterday = 1.day.ago
      today = Date.today
      expect(create(:distribution, created_at: yesterday, issued_at: today).issued_at).to eq(today)
      expect(create(:distribution, created_at: yesterday).issued_at).to eq(yesterday)
    end
  end

  context "Methods >" do
    let(:distribution) { create(:distribution) }
    let(:item) { create(:item, name: "AAA", category: "Foo") }
    let(:donation) { create(:donation) }

    describe "#distributed_at" do
      it "displays either the explicit distributed_at date, or falls-through to issued_at" do
        two_days_ago = 2.days.ago
        expect(create(:distribution, issued_at: two_days_ago).distributed_at).to eq(two_days_ago.strftime("%B %-d %Y"))
        expect(create(:distribution).distributed_at).to eq(Time.zone.now.strftime("%B %-d %Y"))
      end
    end

    describe "#copy_line_items" do
      it "replicates line_items from a donation into a distribution" do
        donation.line_items << create(:line_item, item: item, quantity: 5)
        donation.line_items << create(:line_item, item: item, quantity: 10)
        expect(distribution.copy_line_items(donation.id).count).to eq 2
      end
    end

    describe "#combine_duplicates" do
      it "condenses duplicate line_items if the item_ids match" do
        distribution.line_items << create(:line_item, item: item, quantity: 5)
        distribution.line_items << create(:line_item, item: item, quantity: 10)
        distribution.combine_duplicates
        expect(distribution.line_items.size).to eq 1
        expect(distribution.line_items.first.quantity).to eq 15
      end
    end
  end
end

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
        create(:distribution, created_at: Time.zone.today)
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
      today = Time.zone.today
      expect(create(:distribution, created_at: yesterday, issued_at: today).issued_at).to eq(today)
      expect(create(:distribution, created_at: yesterday).issued_at).to eq(yesterday)
    end
  end

  context "Methods >" do
    let(:distribution) { create(:distribution) }
    let(:item) { create(:item, name: "AAA") }
    let(:donation) { create(:donation) }

    describe "#distributed_at" do
      it "displays explicit issued_at date" do
        two_days_ago = 2.days.ago.midnight
        distribution.issued_at = Time.zone.parse("2014-03-01 14:30:00 UTC")
        expect(create(:distribution, issued_at: two_days_ago).distributed_at).to eq(two_days_ago.to_s(:distribution_date))
      end

      it "shows the hour and minutes if it has been provided" do
        distribution.issued_at = Time.zone.parse("2014-03-01 14:30:00 UTC")
        expect(distribution.distributed_at).to eq("March 1 2014 2:30pm")
      end
    end

    describe "#copy_line_items" do
      it "replicates line_items from a donation into a distribution" do
        donation.line_items << create(:line_item, item: item, quantity: 5, itemizable: donation)
        donation.line_items << create(:line_item, item: item, quantity: 10, itemizable: donation)
        expect(distribution.copy_line_items(donation.id).count).to eq 2
      end
    end

    describe "#combine_duplicates" do
      it "condenses duplicate line_items if the item_ids match" do
        distribution.line_items << create(:line_item, item: item, quantity: 5, itemizable: distribution)
        distribution.line_items << create(:line_item, item: item, quantity: 10, itemizable: distribution)
        distribution.combine_duplicates
        expect(distribution.line_items.size).to eq 1
        expect(distribution.line_items.first.quantity).to eq 15
      end
    end

    describe "#replace_distribution!" do
      subject { create(:distribution, :with_items, item_quantity: 10) }
      let(:attributes) { { line_items_attributes: { "0": { item_id: subject.line_items.first.item_id, quantity: 2 } } } }

      it "replaces a big distribution with a smaller one, resulting in increased stored quantities" do
        expect do
          subject.replace_distribution!(attributes)
        end.to change { subject.storage_location.size }.by(8)
      end
    end
  end
end

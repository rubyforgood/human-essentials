# == Schema Information
#
# Table name: distributions
#
#  id                     :integer          not null, primary key
#  agency_rep             :string
#  comment                :text
#  delivery_method        :integer          default("pick_up"), not null
#  issued_at              :datetime
#  reminder_email_enabled :boolean          default(FALSE), not null
#  shipping_cost          :decimal(8, 2)
#  state                  :integer          default("scheduled"), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  organization_id        :integer
#  partner_id             :integer
#  storage_location_id    :integer
#

RSpec.describe Distribution, type: :model do
  let(:organization) { create(:organization) }

  it_behaves_like "itemizable"

  context "Validations >" do
    it { should validate_presence_of(:organization) }
    it { should validate_presence_of(:partner) }
    it { should validate_presence_of(:storage_location) }

    it "ensures the associated line_items are valid" do
      organization = create(:organization)
      storage_location = create(:storage_location, organization: organization)
      d = build(:distribution, storage_location: storage_location)
      line_item = build(:line_item, quantity: 1, item: create(:item, organization: organization))
      TestInventory.create_inventory(organization, {
        storage_location.id => { line_item.item_id => 10 }
      })
      d.line_items << line_item
      expect(d).to be_valid
    end

    it "ensures the associated line_items are invalid with a nil quantity" do
      d = build(:distribution)
      d.line_items << build(:line_item, quantity: nil)
      expect(d).not_to be_valid
    end

    it "ensures the associated line_items are invalid with a zero quantity" do
      d = build(:distribution)
      d.line_items << build(:line_item, quantity: 0)
      expect(d).not_to be_valid
    end

    it "ensures that any included items are found in the associated storage location" do
      unless Event.read_events?(organization) # not relevant in event world
        d = build(:distribution)
        item_missing = create(:item, name: "missing")
        d.line_items << build(:line_item, item: item_missing)
        expect(d).not_to be_valid
      end
    end

    it "ensures that the issued at is no earlier than 2000" do
      d = build(:distribution, issued_at: "1999-12-31")
      expect(d).not_to be_valid
    end

    context "when delivery method is shipped" do
      context "shipping cost is negative" do
        let(:distribution) { build(:distribution, delivery_method: "shipped", shipping_cost: -13) }
        it "will not allow to save distribution" do
          expect(distribution).not_to be_valid
        end
      end

      context "shipping cost is none negative" do
        let(:distribution) { create(:distribution, delivery_method: "shipped", shipping_cost: 13.09) }
        it "allows to save distribution" do
          expect(distribution).to be_valid
        end
      end
    end

    context "when delivery method is other then shipped" do
      let(:distribution) { create(:distribution, delivery_method: "delivery", shipping_cost: -13) }
      it "allows to save distribution" do
        expect(distribution).to be_valid
      end
    end
  end

  context "Scopes >" do
    describe "during >" do
      it "returns all distributions created between two dates" do
        Distribution.destroy_all
        # The models should default to assigning the created_at time to the issued_at
        create(:distribution, created_at: Time.zone.today)
        # but just for fun we'll force one in the past within the range
        create(:distribution, issued_at: Date.yesterday)
        # and one outside the range
        create(:distribution, issued_at: 1.year.ago)
        expect(Distribution.during(Time.zone.now - 1.week..Time.zone.now + 2.days).size).to eq(2)
      end
    end

    describe "this_week >" do
      context "When it's Sunday (end of the week)" do
        before do
          travel_to Time.zone.local(2019, 6, 30)
        end

        after do
          travel_back
        end

        it "doesn't include distributions past Sunday" do
          sunday_distribution = create(:distribution, organization: organization, issued_at: Time.zone.local(2019, 6, 30))
          create(:distribution, organization: organization, issued_at: Time.zone.local(2019, 7, 1))
          distributions = Distribution.this_week
          expect(distributions.count).to eq(1)
          expect(distributions.first).to eq(sunday_distribution)
        end
      end

      context "When it's Tuesday (mid-week)" do
        before do
          travel_to Time.zone.local(2019, 7, 2)
        end

        after do
          travel_back
        end

        it "includes distributions as early as Monday and as late as upcoming Sunday" do
          create(:distribution, organization: organization, issued_at: Time.zone.local(2019, 6, 30))
          tuesday_distribution = create(:distribution, organization: organization, issued_at: Time.zone.local(2019, 7, 2))
          sunday_distribution = create(:distribution, organization: organization, issued_at: Time.zone.local(2019, 7, 7))
          distributions = Distribution.this_week
          expect(distributions.count).to eq(2)
          expect(distributions.first).to eq(tuesday_distribution)
          expect(distributions.last).to eq(sunday_distribution)
        end
      end
    end

    describe "by_item_id >" do
      it "only returns distributions with given item id" do
        # create 2 items with unique ids
        item1 = create(:item)
        item2 = create(:item)
        # create a distribution with each item
        create(:distribution, :with_items, item: item1)
        create(:distribution, :with_items, item: item2)
        # filter should only return 1 distribution
        expect(Distribution.by_item_id(item1.id).size).to eq(1)
      end
    end

    describe "by_partner >" do
      let!(:partner1) { create(:partner, name: "Howdy Doody", email: "howdood@example.com") }
      let!(:partner2) { create(:partner, name: "Doug E Doug", email: "ded@example.com") }
      let!(:dist1)    { create(:distribution, partner: partner1) }
      let!(:dist2)    { create(:distribution, partner: partner2) }

      it "only returns distributions with given partner id" do
        # filter should only return 1 distribution
        expect(Distribution.by_partner(partner1.id).size).to eq(1)
      end
    end

    describe "by_location >" do
      let!(:location_1) { create(:storage_location) }
      let!(:location_2) { create(:storage_location) }

      it "only returns distributions with given location id" do
        dist1 = create(:distribution, storage_location: location_1)
        dist2 = create(:distribution, storage_location: location_2)

        expect(Distribution.by_location(location_1.id)).to include(dist1)
        expect(Distribution.by_location(location_1.id)).not_to include(dist2)
      end
    end
  end

  context "Callbacks >" do
    it "initializes the issued_at field to default to midnight if it wasn't explicitly set" do
      yesterday = 1.day.ago
      today = Time.zone.today

      distribution = create(:distribution, created_at: yesterday, issued_at: today)
      expect(distribution.issued_at.to_date).to eq(today)

      distribution = create(:distribution, created_at: yesterday)
      expect(distribution.issued_at).to eq(distribution.created_at.end_of_day)
    end

    context "#before_save" do
      context "#reset_shipping_cost" do
        context "when delivery_method is other then shipped" do
          let(:distribution) { create(:distribution, delivery_method: "delivery", shipping_cost: 12.05) }

          it "distribution will be created successfully and the shipping_cost will be zero" do
            expect(distribution.errors).to be_empty
            expect(distribution.shipping_cost).to be_nil
          end
        end
      end
    end
  end

  context "Methods >" do
    let(:distribution) { create(:distribution) }
    let(:item) { create(:item, name: "AAA") }
    let(:donation) { create(:donation) }

    describe "#distributed_at" do
      it "displays explicit issued_at date" do
        two_days_ago = 2.days.ago.midnight
        distribution.issued_at = Time.zone.parse("2014-03-01 14:30:00")
        expect(create(:distribution, issued_at: two_days_ago).distributed_at).to eq(two_days_ago.to_fs(:distribution_date))
      end

      it "shows the hour and minutes if it has been provided" do
        distribution.issued_at = Time.zone.parse("2014-03-01 14:30:00")
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
        distribution.reload.combine_duplicates
        expect(distribution.line_items.size).to eq 1
        expect(distribution.line_items.first.quantity).to eq 15
      end
    end

    describe "#copy_from_request" do
      it "copy over relevant request information into the distrubution" do
        item1 = create(:item, name: "Item1", organization: organization)
        item2 = create(:item, name: "Item2", organization: organization)
        request = create(:request,
          organization: organization,
          partner_user: create(:partner_user),
          request_items: [
            { item_id: item1.id, quantity: 15 },
            { item_id: item2.id, quantity: 18 }
          ])
        distribution = Distribution.new
        distribution.copy_from_request(request.id)
        expect(distribution.line_items.size).to eq 2
        expect(distribution.line_items.first.quantity).to eq 15
        expect(distribution.line_items.second.quantity).to eq 18
        expect(distribution.organization_id).to eq organization.id
        expect(distribution.partner_id).to eq request.partner_id
        expect(distribution.agency_rep).to eq "#{request.partner_user.name} <#{request.partner_user.email}>"
        expect(distribution.comment).to eq request.comments
        expect(distribution.issued_at.to_date).to eq(Time.zone.today + 1.day)
      end
    end

    describe "#future?" do
      let(:dist1)    { create(:distribution, issued_at: Time.zone.tomorrow) }
      let(:dist2)    { create(:distribution, issued_at: Time.zone.yesterday) }

      context "when issued_at has not passed" do
        it "returns true" do
          expect(dist1.future?).to be true
        end
      end

      context "when issued_at has passed" do
        it "returns false" do
          expect(dist2.future?).to be false
        end
      end
    end
  end

  context "CSV export >" do
    let(:organization_2) { create(:organization) }
    let(:item1) { create(:item, organization: organization) }
    let(:item2) { create(:item, organization: organization) }
    let!(:distribution_1) { create(:distribution, :with_items, item: item1, organization: organization, issued_at: 3.days.ago) }
    let!(:distribution_2) { create(:distribution, :with_items, item: item2, organization: organization, issued_at: 1.day.ago) }
    let!(:distribution_3) { create(:distribution, organization: organization_2, issued_at: Time.zone.today) }

    describe "for_csv_export >" do
      it "filters only to the given organization" do
        expect(Distribution.for_csv_export(organization)).to match_array [distribution_1, distribution_2]
      end

      it "filters only to the given filter" do
        expect(Distribution.for_csv_export(organization, { by_item_id: item1.id })).to match_array [distribution_1]
      end

      it "filters only to the given issue time range" do
        expect(Distribution.for_csv_export(organization, {}, 4.days.ago..2.days.ago)).to match_array [distribution_1]
      end
    end

    describe "csv_export_attributes" do
      let(:item) { create(:item, organization: organization) }
      let!(:distribution) { create(:distribution, :with_items, item: item, organization: organization, issued_at: 3.days.ago) }

      it "returns the set of attributes which define a row in case of distribution export" do
        distribution_details = [distribution].map(&:csv_export_attributes).first
        expect(distribution_details[0]).to eq distribution.partner.name
        expect(distribution_details[1]).to eq distribution.issued_at.strftime("%F")
        expect(distribution_details[2]).to eq distribution.storage_location.name
        expect(distribution_details[3]).to eq distribution.line_items.total
        expect(distribution_details[5]).to eq distribution.delivery_method
        expect(distribution_details[6]).to eq distribution.state
        expect(distribution_details[7]).to eq distribution.agency_rep
      end
    end
  end

  describe "versioning" do
    it { is_expected.to be_versioned }
  end
end

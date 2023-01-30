# == Schema Information
#
# Table name: donations
#
#  id                           :integer          not null, primary key
#  comment                      :text
#  issued_at                    :datetime
#  money_raised                 :integer
#  source                       :string
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  donation_site_id             :integer
#  manufacturer_id              :bigint
#  organization_id              :integer
#  product_drive_id             :bigint
#  product_drive_participant_id :integer
#  storage_location_id          :integer
#

RSpec.describe Donation, type: :model do
  it_behaves_like "itemizable"
  # This mixes feature specs with model specs... idealy we do not want to do this
  # it_behaves_like "pagination"

  context "Validations >" do
    it "must belong to an organization" do
      expect(build(:donation, organization_id: nil)).not_to be_valid
    end
    it "requires a donation_site if the source is 'Donation Site'" do
      expect(build_stubbed(:donation_site_donation, source: "Donation Site", donation_site: nil)).not_to be_valid
      expect(build(:donation, source: "Misc. Donation", donation_site: nil)).to be_valid
      expect(build_stubbed(:manufacturer_donation, source: "Manufacturer", donation_site: nil)).to be_valid
    end
    it "requires a product drive participant if the source is 'Product Drive'" do
      expect(build_stubbed(:product_drive_donation, source: "Product Drive Participant", product_drive_participant_id: nil)).not_to be_valid
      expect(build_stubbed(:manufacturer_donation, source: "Manufacturer", product_drive_participant_id: nil)).to be_valid
      expect(build(:donation, source: "Misc. Donation", product_drive_participant_id: nil)).to be_valid
    end
    it "requires a manufacturer if the source is 'Manufacturer'" do
      expect(build_stubbed(:manufacturer_donation, source: "Manufacturer", manufacturer: nil)).not_to be_valid
      expect(build_stubbed(:product_drive_donation, source: "Product Drive", manufacturer: nil)).to be_valid
      expect(build(:donation, source: "Misc. Donation", manufacturer: nil)).to be_valid
    end
    it "requires a source from the list of available sources" do
      expect(build(:donation, source: nil)).not_to be_valid
      expect(build(:donation, source: "Something new")).not_to be_valid
    end
    it "requires an inventory (storage location)" do
      expect(build(:donation, storage_location_id: nil)).not_to be_valid
    end
    it "is invalid when the line items are invalid" do
      d = build(:donation)
      d.line_items << build(:line_item, quantity: nil)
      expect(d).not_to be_valid
    end
  end

  context "Callbacks >" do
    it "inititalizes the issued_at field to default to created_at if it wasn't explicitly set" do
      yesterday = 1.day.ago
      today = Time.zone.today

      donation = create(:donation, created_at: yesterday, issued_at: today)
      expect(donation.issued_at.to_date).to eq(today)

      donation = create(:donation, created_at: yesterday)
      expect(donation.issued_at).to eq(donation.created_at)
    end

    it "automatically combines duplicate line_item records when they're created" do
      donation = build(:donation)
      item = create(:item)
      donation.line_items.build(item_id: item.id, quantity: 5)
      donation.line_items.build(item_id: item.id, quantity: 10)
      donation.save
      expect(donation.line_items.size).to eq(1)
      expect(donation.line_items.first.quantity).to eq(15)
    end
  end

  context "Scopes >" do
    describe "during >" do
      it "returns all donations created between two dates" do
        Donation.destroy_all
        # The models should default to assigning the created_at time to the issued_at
        create(:donation, created_at: Time.zone.today)
        # but just for fun we'll force one in the past within the range
        create(:donation, issued_at: Date.yesterday)
        # and one outside the range
        create(:donation, issued_at: 1.year.ago)
        expect(Donation.during(1.month.ago..Date.tomorrow).size).to eq(2)
      end
    end

    describe "by_source >" do
      subject(:by_source) { Donation.by_source(source).count }

      before(:each) do
        create(:donation, source: Donation::SOURCES[:misc])
        create(:product_drive_donation)
      end

      context "when source is not a symbol" do
        context "when source comes from the SOURCES hash" do
          let(:source) { Donation::SOURCES[:product_drive] }

          it "returns all donations with the provided source" do
            is_expected.to eq(1)
          end
        end

        context "when source is invalid" do
          let(:source) { "Invalid String" }

          it "does not throw errors, returns no results" do
            is_expected.to be_zero
          end
        end
      end

      context "when source is a symbol" do
        context "when source is valid" do
          let(:source) { :product_drive }

          it "allows a symbol as an argument, referencing the SOURCES hash" do
            is_expected.to eq(1)
          end
        end

        context "when source is invalid" do
          let(:source) { :invalid }

          it "does not throw errors, returns no results" do
            is_expected.to be_zero
          end
        end
      end
    end
  end

  context "Associations >" do
    describe "items >" do
      it "has_many" do
        donation = create(:donation)
        create(:line_item, :donation, itemizable: donation)
        expect(donation.items.count).to eq(1)
      end
    end
  end

  context "Methods >" do
    describe "remove" do
      let!(:donation) { create(:donation, :with_items) }

      it "removes the item from the donation" do
        item_id = donation.line_items.last.item_id
        expect do
          donation.remove(item_id)
        end.to change { donation.line_items.count }.by(-1)
      end

      it "works with either an id or an object" do
      end

      it "fails gracefully if the item doesn't exist" do
        item_id = create(:item).id
        expect do
          donation.remove(item_id)
        end.not_to change { donation.line_items.count }
      end
    end

    describe "money_raised" do
      it "tracks the money raised in a donation" do
        donation = create(:donation, :with_items, money_raised: 100)
        expect(donation.money_raised).to eq(100)
      end
    end

    describe "replace_increase!" do
      let!(:storage_location) { create(:storage_location, organization: @organization) }
      subject { create(:donation, :with_items, organization: @organization, item_quantity: 5, storage_location: storage_location) }

      context "changing the donation" do
        let(:attributes) { { line_items_attributes: { "0": { item_id: subject.line_items.first.item_id, quantity: 2 } } } }

        it "updates the quantity of items" do
          subject
          expect do
            subject.replace_increase!(attributes)
            storage_location.reload
          end.to change { storage_location.size }.by(-3)
        end
      end

      context "when adding an item that has been previously deleted" do
        let!(:inactive_item) { create(:item, active: false) }
        let(:attributes) { { line_items_attributes: { "0": { item_id: inactive_item.to_param, quantity: 10 } } } }

        it "re-creates the item" do
          subject
          expect do
            subject.replace_increase!(attributes)
            storage_location.reload
          end.to change { storage_location.size }.by(5) # We had 5 items of a different kind before, now we have 10
                                                 .and change { Item.active.count }.by(1)
        end
      end
    end

    describe "source_view" do
      context "from a drive" do
        let!(:donation) { create(:product_drive_donation, product_drive_participant: product_drive_participant, product_drive: product_drive) }

        let(:product_drive) { create(:product_drive, name: "Test Drive") }

        context "participant known" do
          let(:product_drive_participant) { create(:product_drive_participant, contact_name: contact_name) }

          context "contact name present" do
            let(:contact_name) { "Contact Name" }

            it "returns participant display name" do
              expect(donation.source_view).to eq("Contact Name (participant)")
            end
          end

          context "no contact name" do
            let(:contact_name) { nil }

            it "returns drive display name" do
              expect(donation.source_view).to eq("Test Drive (product drive)")
            end
          end
        end

        context "unknown participant" do
          let(:product_drive_participant) { nil }

          it "returns drive display name" do
            expect(donation.source_view).to eq("Test Drive (product drive)")
          end
        end
      end

      context "not from a drive" do
        let!(:donation) { create(:manufacturer_donation) }

        it "returns source" do
          expect(donation.source_view).to eq(donation.source)
        end
      end
    end
  end

  describe "SOURCES" do
    it "is a hash that is referenceable by key to avoid 'magic strings'" do
      expect(Donation::SOURCES).to have_key(:product_drive)
      expect(Donation::SOURCES).to have_key(:donation_site)
      expect(Donation::SOURCES).to have_key(:misc)
    end

    specify 'the hash is immutable' do
      expect { Donation::SOURCES[:foo] = 'bar' }.to raise_error(FrozenError)
    end

    specify 'the hash values are immutable' do
      Donation::SOURCES.values.each do |frozen_string|
        expect { frozen_string << 'bar' }.to raise_error(FrozenError)
      end
    end
  end
end

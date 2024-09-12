# == Schema Information
#
# Table name: purchases
#
#  id                                       :bigint           not null, primary key
#  amount_spent_in_cents                    :integer
#  amount_spent_on_adult_incontinence_cents :integer          default(0), not null
#  amount_spent_on_diapers_cents            :integer          default(0), not null
#  amount_spent_on_other_cents              :integer          default(0), not null
#  amount_spent_on_period_supplies_cents    :integer          default(0), not null
#  comment                                  :text
#  issued_at                                :datetime
#  purchased_from                           :string
#  created_at                               :datetime         not null
#  updated_at                               :datetime         not null
#  organization_id                          :integer
#  storage_location_id                      :integer
#  vendor_id                                :integer
#

RSpec.describe Purchase, type: :model do
  it_behaves_like "itemizable"

  context "Validations >" do
    it { should belong_to(:organization) }
    it { should belong_to(:storage_location) }
    it { should belong_to(:vendor) }

    it "is valid if categories have no values" do
      d = build(:purchase, amount_spent_in_cents: 450)
      expect(d).to be_valid
    end

    # re 2813_update_annual_report, adding in amount_spent_on_period_supplies_cents to test.
    # also adding in amount_spend_on_incontinence_cents because it was missing.

    it "is not valid if any category is non-zero but does not add up to the total" do
      d = build(:purchase, amount_spent_in_cents: 450, amount_spent_on_diapers_cents: 300)
      expect(d).not_to be_valid
      d = build(:purchase, amount_spent_in_cents: 450, amount_spent_on_adult_incontinence_cents: 300)
      expect(d).not_to be_valid
      d = build(:purchase, amount_spent_in_cents: 450, amount_spent_on_period_supplies_cents: 300)
      expect(d).not_to be_valid
      d = build(:purchase, amount_spent_in_cents: 450, amount_spent_on_other_cents: 300)
      expect(d).not_to be_valid
    end

    it "is valid if all categories add up to total" do
      d = build(:purchase, amount_spent_in_cents: 1150,
        amount_spent_on_diapers_cents: 200,
        amount_spent_on_adult_incontinence_cents: 300,
        amount_spent_on_period_supplies_cents: 400,
        amount_spent_on_other_cents: 250)
      expect(d).to be_valid
    end

    # 2813 update annual reports -- this covers off making sure it's checking the case of period supplies only (which it won't be before we make it so)

    it "is not valid if period supplies is non-zero but no other category is " do
      d = build(:purchase, amount_spent_in_cents: 450, amount_spent_on_diapers_cents: 0,
        amount_spent_on_adult_incontinence_cents: 0,
        amount_spent_on_period_supplies_cents: 350,
        amount_spent_on_other_cents: 0)
      expect(d).not_to be_valid
      expect(d.errors.full_messages)
        .to eq(["Amount spent does not equal all categories - categories add to $3.50 but given total is $4.50"])
    end

    it "is not valid if categories do not add up" do
      d = build(:purchase, amount_spent_in_cents: 450, amount_spent_on_diapers_cents: 200,
        amount_spent_on_adult_incontinence_cents: 250,
        amount_spent_on_period_supplies_cents: 350,
        amount_spent_on_other_cents: 725)
      expect(d).not_to be_valid
      expect(d.errors.full_messages)
        .to eq(["Amount spent does not equal all categories - categories add to $15.25 but given total is $4.50"])
    end

    it "ensures that the issued at is no earlier than 2000" do
      p = build(:purchase, issued_at: "1999-12-31")
      expect(p).not_to be_valid
    end
  end

  context "Callbacks >" do
    it "inititalizes the issued_at field to default to midnight if it wasn't explicitly set" do
      yesterday = 1.day.ago
      today = Time.zone.today

      purchase = create(:purchase, created_at: yesterday, issued_at: today)
      expect(purchase.issued_at.to_date).to eq(today)

      purchase = create(:purchase, created_at: yesterday)
      expect(purchase.issued_at).to eq(purchase.created_at.end_of_day)
    end

    it "automatically combines duplicate line_item records when they're created" do
      purchase = build(:purchase)
      item = create(:item)
      purchase.line_items.build(item_id: item.id, quantity: 5)
      purchase.line_items.build(item_id: item.id, quantity: 10)
      purchase.save
      expect(purchase.line_items.size).to eq(1)
      expect(purchase.line_items.first.quantity).to eq(15)
    end
  end

  context "Scopes >" do
    describe "during >" do
      it "returns all purchases created between two dates" do
        Purchase.destroy_all
        # The models should default to assigning midnight to the issued_at
        create(:purchase, created_at: Time.zone.today)
        # but just for fun we'll force one in the past within the range
        create(:purchase, issued_at: Date.yesterday)
        # and one outside the range
        create(:purchase, issued_at: 1.year.ago)

        expect(Purchase.during(1.month.ago..Time.zone.now + 2.days).size).to eq(2)
      end
    end
  end

  context "Associations >" do
    describe "items >" do
      it "has_many" do
        purchase = create(:purchase)
        create(:line_item, :purchase, itemizable: purchase)
        expect(purchase.items.count).to eq(1)
      end
    end
  end

  context "Methods >" do
    describe "remove" do
      let!(:purchase) { create(:purchase, :with_items) }

      it "removes the item from the purchase" do
        item_id = purchase.line_items.last.item_id
        expect do
          purchase.remove(item_id)
        end.to change { purchase.line_items.count }.by(-1)
      end

      it "fails gracefully if the item doesn't exist" do
        item_id = create(:item).id
        expect do
          purchase.remove(item_id)
        end.not_to change { purchase.line_items.count }
      end
    end

    describe "storage_view" do
      let!(:purchase) { create(:purchase, :with_items) }
      it "returns name of storage location" do
        expect(purchase.storage_view).to eq("Smithsonian Conservation Center")
      end
    end
  end

  describe "versioning" do
    it { is_expected.to be_versioned }
  end
end

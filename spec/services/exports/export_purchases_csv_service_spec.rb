RSpec.describe Exports::ExportPurchasesCSVService do
  describe "#generate_csv_data" do
    subject { described_class.new(purchase_ids: purchase_ids).generate_csv_data }
    let(:purchase_ids) { purchases.map(&:id) }
    let(:duplicate_item) do
      FactoryBot.create(
        :item, name: Faker::Appliance.unique.equipment
      )
    end
    let(:items_lists) do
      [
        [
          [duplicate_item, 5],
          [
            FactoryBot.create(
              :item, name: Faker::Appliance.unique.equipment
            ),
            7
          ],
          [duplicate_item, 3]
        ],
        *(Array.new(3) do |i|
          [[FactoryBot.create(
            :item, name: Faker::Appliance.unique.equipment
          ), i + 1]]
        end)
      ]
    end

    let(:item_names) { items_lists.flatten(1).map(&:first).map(&:name).sort.uniq }

    let(:purchases) do
      start_time = Time.current

      items_lists.each_with_index.map do |items, i|
        purchase = create(
          :purchase,
          vendor: create(
            :vendor, business_name: "Vendor Name #{i}"
          ),
          issued_at: start_time + i.days,
          comment: "This is the #{i}-th purchase in the test.",
          amount_spent_in_cents: i * 4 + 555,
          amount_spent_on_diapers_cents: i + 100,
          amount_spent_on_adult_incontinence_cents: i + 125,
          amount_spent_on_period_supplies_cents: i + 130,
          amount_spent_on_other_cents: i + 200
        )

        items.each do |(item, quantity)|
          purchase.line_items << create(
            :line_item, quantity: quantity, item: item
          )
        end

        purchase
      end
    end

    let(:expected_headers) do
      [
        "Purchases from",
        "Storage Location",
        "Purchased Date",
        "Quantity of Items",
        "Variety of Items",
        "Amount Spent",
        "Spent on Diapers",
        "Spent on Adult Incontinence",
        "Spent on Period Supplies",
        "Spent on Other",
        "Comment"
      ] + expected_item_headers
    end

    let(:total_item_quantities) do
      template = item_names.index_with(0)

      items_lists.map do |items_list|
        row = template.dup
        items_list.each do |(item, quantity)|
          row[item.name] += quantity
        end
        row.values
      end
    end

    let(:expected_item_headers) do
      expect(item_names).not_to be_empty

      item_names
    end

    it "should match the expected content for the csv" do
      expect(subject[0]).to eq(expected_headers)

      purchases.zip(total_item_quantities).each_with_index do |(purchase, total_item_quantity), idx|
        row = [
          purchase.vendor.try(:business_name),
          purchase.storage_view,
          purchase.issued_at.strftime("%F"),
          purchase.line_items.total,
          total_item_quantity.count(&:positive?),
          purchase.amount_spent,
          purchase.amount_spent_on_diapers,
          purchase.amount_spent_on_adult_incontinence,
          purchase.amount_spent_on_period_supplies,
          purchase.amount_spent_on_other,
          purchase.comment
        ]

        row += total_item_quantity

        expect(subject[idx + 1]).to eq(row)
      end
    end
  end
end

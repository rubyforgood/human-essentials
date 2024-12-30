RSpec.describe Exports::ExportDonationsCSVService do
  let(:organization) { create(:organization) }
  describe '#generate_csv_data' do
    subject { described_class.new(donation_ids: donation_ids, organization: organization).generate_csv_data }
    let(:donation_ids) { donations.map(&:id) }
    let(:duplicate_item) { FactoryBot.create(:item, value_in_cents: 10) }
    let(:items_lists) do
      [
        [
          [duplicate_item, 5],
          [FactoryBot.create(:item), 7],
          [duplicate_item, 3]
        ],
        *(Array.new(3) do |i|
          [[FactoryBot.create(
            :item, name: "item_#{i}", value_in_cents: i + 1
          ), i + 1]]
        end)
      ]
    end

    let(:item_names) { items_lists.flatten(1).map(&:first).map(&:name).sort.uniq }

    let(:donations) do
      start_time = Time.current

      items_lists.each_with_index.map do |items, i|
        donation = create(
          :donation,
          donation_site: create(
            :donation_site, name: "Space Needle #{i}",
          ),
          issued_at: start_time + i.days,
          comment: "This is the #{i}-th donation in the test."
        )

        items.each do |(item, quantity)|
          donation.line_items << create(
            :line_item, quantity: quantity, item: item
          )
        end

        donation
      end
    end

    let(:expected_headers) do
      [
        "Source",
        "Date",
        "Details",
        "Storage Location",
        "Quantity of Items",
        "Variety of Items",
        "In-Kind Total",
        "Comments"
      ] + expected_item_headers
    end

    let(:quantities_of_items) do
      template = item_names.index_with(0)

      items_lists.map do |items_list|
        row = template.dup
        items_list.each do |(item, quantity)|
          row[item.name] += quantity
        end
        row.values
      end
    end

    context 'while "Include in-kind value in donation and distribution exports?" is set to no' do
      let(:expected_item_headers) do
        expect(item_names).not_to be_empty

        item_names
      end
      it 'should match the expected content without in-kind value of each item for the csv' do
        expect(subject[0]).to eq(expected_headers)

        donations.zip(quantities_of_items).each_with_index do |(donation, item_quantities), idx|
          total_item_quantity = donation.line_items.total
          row = [
            donation.source,
            donation.issued_at.strftime("%F"),
            donation.details,
            donation.storage_view,
            total_item_quantity,
            item_quantities.count(&:positive?),
            donation.in_kind_value_money.to_f,
            donation.comment
          ]

          row += item_quantities

          expect(item_quantities.sum).to eq(total_item_quantity)
          expect(subject[idx + 1]).to eq(row)
        end
      end
    end

    context 'while "Include in-kind value in donation and distribution exports?" is set to yes' do
      let(:expected_item_headers) do
        expect(item_names).not_to be_empty

        item_names.flat_map { |name| [name, "#{name} In-Kind Value"] }
      end

      let(:quantities_and_values_of_items) do
        template = item_names.index_with({quantity: 0, value: Money.new(0)})

        items_lists.map do |items_list|
          row = template.deep_dup
          items_list.each do |(item, quantity)|
            row[item.name][:quantity] += quantity
            row[item.name][:value] += Money.new(item.value_in_cents * quantity)
          end
          row.values
        end
      end

      it 'should match the expected content with in-kind value of each item for the csv' do
        allow(organization).to receive(:include_in_kind_values_in_exported_files).and_return(true)
        expect(subject[0]).to eq(expected_headers)

        donations.zip(quantities_and_values_of_items).each_with_index do |(donation, quantities_and_values_of_item), idx|
          total_item_count = donation.line_items.total
          total_in_kind_value = donation.in_kind_value_money.to_f
          row = [
            donation.source,
            donation.issued_at.strftime("%F"),
            donation.details,
            donation.storage_view,
            total_item_count,
            quantities_and_values_of_item.map { |item| item[:quantity] }.count(&:positive?),
            total_in_kind_value,
            donation.comment
          ]

          row += quantities_and_values_of_item.flat_map { |item| [item[:quantity], item[:value].to_f] }

          expect(quantities_and_values_of_item.map { |item| item[:quantity] }.sum).to eq(total_item_count)
          expect(quantities_and_values_of_item.map { |item| item[:value] }.sum.to_f).to eq(total_in_kind_value)
          expect(subject[idx + 1]).to eq(row)
        end
      end
    end
  end
end

RSpec.describe Reports::ChildrenServedReportService, type: :service do
  let(:year) { 2020 }

  describe '#report' do
    context "when organization has no distributions" do
      it 'should report zero values' do
        organization = create(:organization)
        report = described_class.new(organization: organization, year: year).report
        expect(report).to eq({
                                      name: 'Children Served',
                                      entries: {
                                        'Average children served monthly' => "0",
                                        'Total children served' => "0",
                                        'Repackages diapers?' => 'N',
                                        'Monthly diaper distributions?' => 'N'
                                      }
                                    })
      end
    end

    context "when organization has distributions" do
      before(:each) do
        @organization = create(:organization, :with_items, distribute_monthly: true, repackage_essentials: true)
        @within_time = Time.zone.parse("2020-05-31 14:00:00")
        outside_time = Time.zone.parse("2019-05-31 14:00:00")

        @disposable_item = @organization.items.disposable.first
        non_disposable_item = @organization.items.where.not(id: @organization.items.disposable).first

        # Distributions
        distributions = create_list(:distribution, 2, issued_at: @within_time, organization: @organization)
        outside_distributions = create_list(:distribution, 2, issued_at: outside_time, organization: @organization)
        (distributions + outside_distributions).each do |dist|
          create_list(:line_item, 5, :distribution, quantity: 200, item: @disposable_item, itemizable: dist)
          create_list(:line_item, 5, :distribution, quantity: 300, item: non_disposable_item, itemizable: dist)
        end
        # 2 distributions within time * 5 disposable line items * 200 disposable items per disposable line item * disposable_item distribution_quantity
        # = 2000 * disposable_item distribution_quantity

        kit_params = attributes_for(:kit)
        kit_params[:line_items_attributes] = [
          {item_id: @disposable_item, quantity: 2}
        ]
        kit_containing_disposable = KitCreateService.new(organization_id: @organization.id, kit_params: kit_params).call.kit
        kit_params = attributes_for(:kit)
        kit_params[:line_items_attributes] = [
          {item_id: non_disposable_item, quantity: 3}
        ]
        kit_containing_non_disposable = KitCreateService.new(organization_id: @organization.id, kit_params: kit_params).call.kit

        kits_distribution = create(:distribution, organization: @organization, issued_at: @within_time)
        create(:line_item, :distribution, quantity: 10, item: kit_containing_disposable.item, itemizable: kits_distribution)
        create(:line_item, :distribution, quantity: 10, item: kit_containing_non_disposable.item, itemizable: kits_distribution)
        # (2000 * disposable_item distribution_quantity) + (10 kits containing disposable items * 2 disposable items per kit * disposable_item distribution_quantity)
        # = 2020 * disposable_item distribution_quantity
      end

      it 'should report normal values with distribution quantity correctly' do
        @disposable_item.update!(distribution_quantity: 20)
        # 2020 / 20 = 101 children served
        report = described_class.new(organization: @organization, year: @within_time.year).report
        expect(report).to eq({
          name: 'Children Served',
          entries: {
            'Average children served monthly' => "8",
            'Total children served' => "101",
            'Repackages diapers?' => 'Y',
            'Monthly diaper distributions?' => 'Y'
          }
        })
      end
      it 'should work with no distribution_quantity' do
        # 2020 / item.default_quantity (50) = 40.4
        report = described_class.new(organization: @organization, year: @within_time.year).report
        expect(report).to eq({
          name: 'Children Served',
          entries: {
            'Average children served monthly' => "3",
            'Total children served' => "41",
            'Repackages diapers?' => 'Y',
            'Monthly diaper distributions?' => 'Y'
          }
        })
      end
    end
  end
end

RSpec.describe Reports::AcquisitionReportService, type: :service, persisted_data: true do
  describe "acquisition report" do
    let(:organization) { create(:organization) }
    let(:within_time) { Time.zone.parse("2020-05-31 14:00:00") }
    let(:outside_time) { Time.zone.parse("2019-05-31 14:00:00") }
    let(:year) { 2020 }

    subject { described_class.new(organization: organization, year: year) }

    before do
      # Kits
      create(:base_item, name: "Adult Disposable Diaper", partner_key: "adult diapers", category: "disposable diaper")
      create(:base_item, name: "Infant Disposable Diaper", partner_key: "infant diapers", category: "disposable diaper")

      disposable_kit_item = create(:item, name: "Adult Disposable Diapers", partner_key: "adult diapers")
      another_disposable_kit_item = create(:item, name: "Infant Disposable Diapers", partner_key: "infant diapers")

      disposable_line_item = create(:line_item, item: disposable_kit_item, quantity: 5)
      another_disposable_line_item = create(:line_item, item: another_disposable_kit_item, quantity: 5)

      disposable_kit = create(:kit, :with_item, organization: organization, line_items: [disposable_line_item])
      another_disposable_kit = create(:kit, :with_item, organization: organization, line_items: [another_disposable_line_item])

      disposable_kit_item_distribution = create(:distribution, organization: organization, issued_at: within_time)
      another_disposable_kit_item_distribution = create(:distribution, organization: organization, issued_at: within_time)

      create(:line_item, :distribution, quantity: 10, item: disposable_kit.item, itemizable: disposable_kit_item_distribution)
      create(:line_item, :distribution, quantity: 10, item: another_disposable_kit.item, itemizable: another_disposable_kit_item_distribution)

      # create disposable and non disposable items
      create(:base_item, name: "3T Diaper", partner_key: "toddler diapers", category: "disposable diaper")
      create(:base_item, name: "Cloth Diapers", partner_key: "infant cloth diapers", category: "cloth diaper")

      disposable_item = create(:item, name: "Disposable Diapers", partner_key: "toddler diapers")
      non_disposable_item = create(:item, name: "Infant Cloth Diapers", partner_key: "infant cloth diapers")

      # Distributions
      distributions = create_list(:distribution, 2, issued_at: within_time, organization: organization)
      outside_distributions = create_list(:distribution, 2, issued_at: outside_time, organization: organization)

      (distributions + outside_distributions).each do |dist|
        create_list(:line_item, 5, :distribution, quantity: 20, item: disposable_item, itemizable: dist)
        create_list(:line_item, 5, :distribution, quantity: 30, item: non_disposable_item, itemizable: dist)
      end

      # Donations outside drives
      non_drive_donations = create_list(:donation, 2,
                                        product_drive: nil,
                                        issued_at: within_time,
                                        money_raised: 1000,
                                        organization: organization)

      non_drive_donations += create_list(:donation, 2,
                                         product_drive: nil,
                                         issued_at: outside_time,
                                         money_raised: 1000,
                                         organization: organization)

      non_drive_donations.each do |donation|
        create_list(:line_item, 3, :donation, quantity: 20, item: disposable_item, itemizable: donation)
        create_list(:line_item, 3, :donation, quantity: 10, item: non_disposable_item, itemizable: donation)
      end

      # Product drives
      drives = create_list(:product_drive, 2,
                           start_date: within_time,
                           end_date: nil,
                           virtual: false,
                           organization: organization)
      outside_drives = create_list(:product_drive, 2,
                                   start_date: outside_time - 1.month,
                                   end_date: outside_time,
                                   organization: organization,
                                   virtual: false)

      donations = (drives + outside_drives).map do |drive|
        create_list(:product_drive_donation, 3,
                    product_drive: drive,
                    issued_at: drive.start_date + 1.day,
                    money_raised: 1000,
                    organization: organization)
      end
      donations.flatten!
      donations.each do |donation|
        create_list(:line_item, 5, :donation, quantity: 20, item: disposable_item, itemizable: donation)
        create_list(:line_item, 5, :donation, quantity: 30, item: non_disposable_item, itemizable: donation)
      end

      # Virtual product drives
      vdrives = create_list(:product_drive, 2,
                            start_date: within_time,
                            end_date: nil,
                            virtual: true,
                            organization: organization)
      outside_vdrives = create_list(:product_drive, 2,
                                    start_date: outside_time - 1.month,
                                    end_date: outside_time,
                                    organization: organization,
                                    virtual: true)

      vdonations = (vdrives + outside_vdrives).map do |drive|
        create(:product_drive_donation,
               product_drive: drive,
               money_raised: 1000,
               issued_at: drive.start_date + 1.day,
               organization: organization)
      end
      vdonations.flatten!
      vdonations.each do |donation|
        create_list(:line_item, 3, :donation, quantity: 20, item: disposable_item, itemizable: donation)
        create_list(:line_item, 3, :donation, quantity: 10, item: non_disposable_item, itemizable: donation)
      end

      # Vendors
      vendors = [
        create(:vendor, business_name: "Vendor 1", organization: organization),
        create(:vendor, business_name: "Vendor 2", organization: organization),
      ]

      # Purchases
      vendors.each do |vendor|
        purchases = [
          create(:purchase,
                 issued_at: within_time,
                 vendor: vendor,
                 organization: organization,
                 purchased_from: 'Google',
                 amount_spent_in_cents: 1000,
                 amount_spent_on_diapers_cents: 1000),
          create(:purchase,
                 issued_at: within_time,
                 vendor: vendor,
                 organization: organization,
                 purchased_from: 'Walmart',
                 amount_spent_in_cents: 2000,
                 amount_spent_on_diapers_cents: 2000),
        ]
        purchases += create_list(:purchase, 2,
                                 issued_at: outside_time,
                                 amount_spent_in_cents: 20_000,
                                 amount_spent_on_diapers_cents: 20_000,
                                 vendor: vendor,
                                 organization: organization)
        purchases.each do |purchase|
          create_list(:line_item, 3, :purchase, quantity: 20, item: disposable_item, itemizable: purchase)
          create_list(:line_item, 3, :purchase, quantity: 10, item: non_disposable_item, itemizable: purchase)
        end
      end
    end

    it "returns the correct quantity of disposable diapers from kits" do
      service = described_class.new(organization: organization, year: within_time.year)
      expect(service.distributed_disposable_diapers_from_kits).to eq(100)
    end

    it 'should return the proper results on #report' do
      expect(subject.report).to eq({
        entries: { "Disposable diapers distributed" => "320",
                   "Cloth diapers distributed" => "300",
                   "Average monthly disposable diapers distributed" => "27",
                   "Total product drives" => 2,
                   "Disposable diapers collected from drives" => "600",
                   "Cloth diapers collected from drives" => "900",
                   "Money raised from product drives" => "$60.00",
                   "Total product drives (virtual)" => 2,
                   "Money raised from product drives (virtual)" => "$20.00",
                   "Disposable diapers collected from drives (virtual)" => "120",
                   "Cloth diapers collected from drives (virtual)" => "60",
                   "Disposable diapers donated" => "840",
                   "% disposable diapers donated" => "78%",
                   "% cloth diapers donated" => "89%",
                   "Disposable diapers purchased" => "240",
                   "% disposable diapers purchased" => "22%",
                   "% cloth diapers purchased" => "11%",
                   "Money spent purchasing diapers" => "$60.00",
                   "Purchased from" => "Google, Walmart",
                   "Vendors diapers purchased through" => "Vendor 1, Vendor 2"},
        name: "Diaper Acquisition"
      })
    end
  end
end

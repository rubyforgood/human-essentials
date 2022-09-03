RSpec.describe Reports::AcquisitionReportService, type: :service, persisted_data: true do
  describe "acquisition report" do
    subject { described_class.new(organization: organization, year: year) }

    let(:organization) { create(:organization) }
    let(:within_time) { Time.zone.parse("2020-05-31 14:00:00") }
    let(:outside_time) { Time.zone.parse("2019-05-31 14:00:00") }
    let(:year) { 2020 }

    before do
      disposable_item = organization.items.disposable.first
      non_disposable_item = organization.items.where.not(id: organization.items.disposable).first

      # We will create data both within and outside our date range, and both disposable and non disposable.
      # Spec will ensure that only the required data is included.

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

    it 'should return the proper results on #report' do
      expect(subject.report).to eq({
        entries: { "% diapers bought" => "22%",
                   "% diapers donated" => "78%",
                   "Average monthly disposable diapers distributed" => "17",
                   "Disposable diapers collected from drives" => "600",
                   "Disposable diapers collected from drives (virtual)" => "120",
                   "Disposable diapers distributed" => "200",
                   "Money raised from product drives" => "$60.00",
                   "Money raised from product drives (virtual)" => "$20.00",
                   "Money spent purchasing diapers" => "$60.00",
                   "Purchased from" => "Google, Walmart",
                   "Total product drives" => 2,
                   "Total product drives (virtual)" => 2,
                   "Vendors diapers purchased through" => "Vendor 1, Vendor 2" },
        name: "Diaper Acquisition"
      })
    end
  end
end

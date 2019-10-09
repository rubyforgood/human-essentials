class PurchasesSeeder
  SUPPLIERS = %w(Target Wegmans Walmart Walgreens).freeze
  COMMENTS = ["Maecenas ante lectus, vestibulum pellentesque arcu sed, eleifend lacinia elit. Cras accumsan varius nisl, a commodo ligula consequat nec. Aliquam tincidunt diam id placerat rutrum.", "Integer a molestie tortor. Duis pretium urna eget congue porta. Fusce aliquet dolor quis viverra volutpat.", "Nullam dictum ac lectus at scelerisque. Phasellus volutpat, sem at eleifend tristique, massa mi cursus dui, eget pharetra ligula arcu sit amet nunc."].freeze

  def self.seed(organization)
    20.times do
      storage_location = random_record_for_org(organization, StorageLocation)
      vendor = random_record_for_org(organization, Vendor)
      Purchase.create(
        purchased_from: SUPPLIERS.sample,
        comment: COMMENTS.sample,
        organization_id: organization.id,
        storage_location_id: storage_location.id,
        amount_spent_in_cents: rand(200..10_000),
        issued_at: (Time.zone.today - rand(15).days),
        created_at: (Time.zone.today - rand(15).days),
        updated_at: (Time.zone.today - rand(15).days),
        vendor_id: vendor.id
      )
    end
  end
end

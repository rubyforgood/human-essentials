require "active_support/testing/time_helpers"

module PDFComparisonTestFactory
  extend ActiveSupport::Testing::TimeHelpers

  StorageCreation = Data.define(:organization, :storage_location, :items)
  FilePaths = Data.define(:expected_pickup_file_path, :expected_same_address_file_path, :expected_different_address_file_path, :expected_incomplete_address_file_path, :expected_no_contact_file_path, :expected_picklist_file_path)

  def self.get_logo_file
    Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/logo.jpg"), "image/jpeg")
  end

  def self.create_organization_storage_items(logo = get_logo_file)
    org = Organization.create!(
      name: "Essentials Bank 1",
      street: "1500 Remount Road",
      city: "Front Royal",
      state: "VA",
      zipcode: "22630",
      email: "email1@example.com",
      logo: logo
    )

    storage_location = StorageLocation.create!(
      name: "Smithsonian Conservation Center",
      address: "1500 Remount Road, Front Royal, VA 22630",
      organization: org
    )

    base_item = BaseItem.find_or_create_by!(name: "10T Diapers", partner_key: "10t_diapers")

    item1 = FactoryBot.create(:item, name: "Item 1", package_size: 50, value_in_cents: 100, organization: org, partner_key: base_item.partner_key)
    item2 = FactoryBot.create(:item, name: "Item 2", value_in_cents: 200, organization: org, partner_key: base_item.partner_key)
    item3 = FactoryBot.create(:item, name: "Item 3", value_in_cents: 300, organization: org, partner_key: base_item.partner_key)
    item4 = FactoryBot.create(:item, name: "Item 4", package_size: 25, value_in_cents: 400, organization: org, partner_key: base_item.partner_key)

    StorageCreation.new(org, storage_location, [item1, item2, item3, item4])
  end

  def self.create_partner(organization)
    Partner.create!(name: "Leslie Sue", organization: organization, email: "leslie1@gmail.com")
  end

  def self.create_partner_with_quota(organization)
    Partner.create!(name: "Leslie Sue", organization: organization, email: "leslie1@gmail.com", quota: 100)
  end

  def self.get_file_paths
    expected_pickup_file_path = Rails.root.join("spec", "fixtures", "files", "distribution_pickup.pdf")
    expected_same_address_file_path = Rails.root.join("spec", "fixtures", "files", "distribution_same_address.pdf")
    expected_different_address_file_path = Rails.root.join("spec", "fixtures", "files", "distribution_program_address.pdf")
    expected_incomplete_address_file_path = Rails.root.join("spec", "fixtures", "files", "distribution_incomplete_address.pdf")
    expected_no_contact_file_path = Rails.root.join("spec", "fixtures", "files", "distribution_no_contact.pdf")
    expected_picklist_file_path = Rails.root.join("spec", "fixtures", "files", "picklist.pdf")

    FilePaths.new(
      expected_pickup_file_path,
      expected_same_address_file_path,
      expected_different_address_file_path,
      expected_incomplete_address_file_path,
      expected_no_contact_file_path,
      expected_picklist_file_path
    )
  end

  private_class_method def self.create_profile(partner:, program_address1:, program_address2:, program_city:, program_state:, program_zip:,
    address1: "Example Address 1", city: "Example City", state: "Example State", zip: "12345", primary_contact_name: "Jaqueline Kihn DDS", primary_contact_email: "van@durgan.example", pick_up_name: nil, pick_up_email: nil, pick_up_phone: nil)
    Partners::Profile.create!(
      partner_id: partner.id,
      essentials_bank_id: partner.organization.id,
      primary_contact_name: primary_contact_name,
      primary_contact_email: primary_contact_email,
      address1: address1,
      address2: "",
      city: city,
      state: state,
      zip_code: zip,
      program_address1: program_address1,
      program_address2: program_address2,
      program_city: program_city,
      program_state: program_state,
      program_zip_code: program_zip,
      pick_up_name: pick_up_name,
      pick_up_email: pick_up_email,
      pick_up_phone: pick_up_phone
    )
  end

  def self.create_profile_no_address(partner)
    create_profile(partner: partner, program_address1: "", program_address2: "", program_city: "", program_state: "", program_zip: "", address1: "", city: "", state: "", zip: "")
  end

  def self.create_profile_without_program_address(partner)
    create_profile(partner: partner, program_address1: "", program_address2: "", program_city: "", program_state: "", program_zip: "")
  end

  def self.create_profile_with_program_address(partner)
    create_profile(partner: partner, program_address1: "Example Program Address 1", program_address2: "", program_city: "Example Program City", program_state: "Example Program State", program_zip: 54321)
  end

  def self.create_profile_with_incomplete_address(partner)
    create_profile(partner: partner, program_address1: "Example Program Address 1", program_address2: "", program_city: "", program_state: "", program_zip: "")
  end

  def self.create_profile_no_contact_with_program_address(partner)
    create_profile(partner: partner, program_address1: "Example Program Address 1", program_address2: "", program_city: "Example Program City", program_state: "Example Program State", program_zip: 54321, primary_contact_name: "", primary_contact_email: "")
  end

  def self.create_profile_with_pickup_person(partner)
    create_profile(
      partner: partner,
      pick_up_name: "Pickup Person",
      pick_up_email: "pickup@example.com",
      pick_up_phone: "1234567890",
      program_address1: "Example Program Address 1",
      program_address2: "",
      program_city: "Example Program City",
      program_state: "Example Program State",
      program_zip: 54321
    )
  end

  def self.create_line_items_for_distribution(distribution, storage_creation)
    LineItem.create!(itemizable: distribution, item: storage_creation.items[0], quantity: 50)
    LineItem.create!(itemizable: distribution, item: storage_creation.items[1], quantity: 100)
  end

  def self.create_line_items_request(partner:, storage_creation:, distribution: nil)
    storage_creation.organization.request_units.find_or_create_by!(name: "pack")
    ItemUnit.find_or_create_by!(item: storage_creation.items[3], name: "pack")
    req1 = Partners::ItemRequest.new(item: storage_creation.items[1], quantity: 30, name: storage_creation.items[1].name, partner_key: storage_creation.items[1].partner_key)
    req2 = Partners::ItemRequest.new(item: storage_creation.items[2], quantity: 50, name: storage_creation.items[2].name, partner_key: storage_creation.items[2].partner_key)
    req3 = Partners::ItemRequest.new(item: storage_creation.items[3], quantity: 120, name: storage_creation.items[3].name, partner_key: storage_creation.items[3].partner_key, request_unit: "pack")
    Request.create!(
      organization: storage_creation.organization,
      partner: partner,
      distribution: distribution,
      request_items: [
        {"item_id" => storage_creation.items[1].id, "quantity" => 30},
        {"item_id" => storage_creation.items[2].id, "quantity" => 50},
        {"item_id" => storage_creation.items[3].id, "quantity" => 120, "request_unit" => "pack"}
      ],
      item_requests: [req1, req2, req3],
      created_at: Time.zone.local(2024, 12, 30, 0, 0, 0)
    )
  end

  def self.create_dist(partner, storage_creation, delivery_method)
    Time.zone = "America/Los_Angeles"
    dist = Distribution.create!(id: 123, partner: partner, delivery_method: delivery_method, issued_at: DateTime.new(2024, 7, 4, 0, 0, 0, "-07:00"), organization: storage_creation.organization, storage_location: storage_creation.storage_location)
    create_line_items_for_distribution(dist, storage_creation)
    create_line_items_request(distribution: dist, partner: partner, storage_creation: storage_creation)
    dist
  end

  def self.render_distribution_pdf_at_year_end(organization, distribution)
    travel_to(Time.zone.local(2024, 12, 30, 0, 0, 0)) do
      return DistributionPdf.new(organization, distribution).compute_and_render
    end
  end

  def self.render_picklist_pdf(organization, requests)
    PicklistsPdf.new(organization, requests).compute_and_render
  end

  private_class_method def self.create_distribution_comparison_pdf(storage_creation, profile_create_method, expected_file_path, delivery_method)
    # Partner creation must be rolled back otherwise Items requested YTD will accumulate
    ActiveRecord::Base.transaction(requires_new: true) do
      partner = create_partner(storage_creation.organization)
      PDFComparisonTestFactory.public_send(profile_create_method, partner)
      dist = create_dist(partner, storage_creation, delivery_method)
      pdf_file = render_distribution_pdf_at_year_end(storage_creation.organization, dist)
      File.binwrite(expected_file_path, pdf_file)
      raise ActiveRecord::Rollback
    end
  end

  private_class_method def self.create_picklist_comparison_pdf(storage_creation, partner_create_method, profile_create_method, expected_file_path)
    # Partner creation must be rolled back otherwise Items requested YTD will accumulate
    ActiveRecord::Base.transaction(requires_new: true) do
      partner = PDFComparisonTestFactory.public_send(partner_create_method, storage_creation.organization)
      PDFComparisonTestFactory.public_send(profile_create_method, partner)
      request = create_line_items_request(partner: partner, storage_creation: storage_creation)
      pdf_file = render_picklist_pdf(storage_creation.organization, [request])
      File.binwrite(expected_file_path, pdf_file)
      raise ActiveRecord::Rollback
    end
  end

  # helper function that can be called from Rails console to generate comparison PDFs
  def self.create_comparison_pdfs
    file_paths = get_file_paths

    # ActiveStorage throws FileNotFoundError in a transaction
    # unless logo is uploaded before transaction
    logo = ActiveStorage::Blob.create_and_upload!(
      io: get_logo_file,
      filename: "logo.jpg",
      content_type: "image/jpeg"
    )

    ActiveRecord::Base.transaction do
      storage_creation = create_organization_storage_items(logo)

      create_distribution_comparison_pdf(storage_creation, :create_profile_no_address, file_paths.expected_pickup_file_path, :pick_up)
      create_distribution_comparison_pdf(storage_creation, :create_profile_without_program_address, file_paths.expected_same_address_file_path, :shipped)
      create_distribution_comparison_pdf(storage_creation, :create_profile_with_program_address, file_paths.expected_different_address_file_path, :delivery)
      create_distribution_comparison_pdf(storage_creation, :create_profile_with_incomplete_address, file_paths.expected_incomplete_address_file_path, :delivery)
      create_distribution_comparison_pdf(storage_creation, :create_profile_no_contact_with_program_address, file_paths.expected_no_contact_file_path, :delivery)

      create_picklist_comparison_pdf(storage_creation, :create_partner_with_quota, :create_profile_with_pickup_person, file_paths.expected_picklist_file_path)

      raise ActiveRecord::Rollback
    end
  end
end

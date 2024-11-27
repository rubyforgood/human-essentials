module DistributionPDFHelper
  StorageCreation = Data.define(:organization, :storage_location, :items)
  FilePaths = Data.define(:expected_pickup_file_path, :expected_same_address_file_path, :expected_different_address_file_path)

  def create_organization_storage_items
    org = FactoryBot.create(:organization,
      name: "Essentials Bank 1",
      street: "1500 Remount Road",
      city: "Front Royal",
      state: "VA",
      zipcode: "22630",
      email: "email1@example.com")

    storage_location = FactoryBot.create(:storage_location, organization: org)
    item1 = FactoryBot.create(:item, name: "Item 1", package_size: 50, value_in_cents: 100)
    item2 = FactoryBot.create(:item, name: "Item 2", value_in_cents: 200)
    item3 = FactoryBot.create(:item, name: "Item 3", value_in_cents: 300)
    item4 = FactoryBot.create(:item, name: "Item 4", package_size: 25, value_in_cents: 400)

    StorageCreation.new(org, storage_location, [item1, item2, item3, item4])
  end

  def create_partner(organization)
    FactoryBot.create(:partner, :uninvited, without_profile: true,
      name: "Leslie Sue",
      organization: organization)
  end

  def get_file_paths
    expected_pickup_file_path = Rails.root.join("spec", "fixtures", "files", "distribution_pickup.pdf")
    expected_same_address_file_path = Rails.root.join("spec", "fixtures", "files", "distribution_same_address.pdf")
    expected_different_address_file_path = Rails.root.join("spec", "fixtures", "files", "distribution_program_address.pdf")

    FilePaths.new(expected_pickup_file_path, expected_same_address_file_path, expected_different_address_file_path)
  end

  private def create_profile(partner:, program_address1:, program_address2:, program_city:, program_state:, program_zip:,
    address1: "Example Address 1", city: "Example City", state: "Example State", zip: "12345")

    FactoryBot.create(:partner_profile,
      partner_id: partner.id,
      primary_contact_name: "Jaqueline Kihn DDS",
      primary_contact_email: "van@durgan.example",
      address1: address1,
      address2: "",
      city: city,
      state: state,
      zip_code: zip,
      program_address1: program_address1,
      program_address2: program_address2,
      program_city: program_city,
      program_state: program_state,
      program_zip_code: program_zip)
  end

  def create_profile_no_address(partner)
    create_profile(partner: partner, program_address1: "", program_address2: "", program_city: "", program_state: "", program_zip: "", address1: "", city: "", state: "", zip: "")
  end

  def create_profile_without_program_address(partner)
    create_profile(partner: partner, program_address1: "", program_address2: "", program_city: "", program_state: "", program_zip: "")
  end

  def create_profile_with_program_address(partner)
    create_profile(partner: partner, program_address1: "Example Program Address 1", program_address2: "", program_city: "Example Program City", program_state: "Example Program State", program_zip: 54321)
  end

  def create_line_items_request(distribution, storage_creation)
    FactoryBot.create(:line_item, itemizable: distribution, item: storage_creation.items[0], quantity: 50)
    FactoryBot.create(:line_item, itemizable: distribution, item: storage_creation.items[1], quantity: 100)
    FactoryBot.create(:item_unit, item: storage_creation.items[3], name: "pack")
    FactoryBot.create(:request, :with_item_requests, distribution: distribution,
      request_items: [
        {"item_id" => storage_creation.items[1].id, "quantity" => 30},
        {"item_id" => storage_creation.items[2].id, "quantity" => 50},
        {"item_id" => storage_creation.items[3].id, "quantity" => 120, "request_unit" => "pack"}
])
  end

  def create_dist(partner, storage_creation, delivery_method)
    Time.zone = "America/Los_Angeles"
    dist = FactoryBot.create(:distribution, partner: partner, delivery_method: delivery_method, issued_at: DateTime.new(2024, 7, 4, 0, 0, 0, "-07:00"), organization: storage_creation.organization, storage_location: storage_creation.storage_location)
    create_line_items_request(dist, storage_creation)
    dist
  end

  def compare_pdf(organization, distribution, expected_file_path)
    pdf = DistributionPdf.new(organization, distribution)
    begin
      pdf_file = pdf.compute_and_render

      # Run the following from Rails sandbox console (bin/rails/console --sandbox) to regenerate these comparison PDFs:
      # => load "spec/support/distribution_pdf_helper.rb"
      # => Rails::ConsoleMethods.send(:prepend, DistributionPDFHelper)
      # => create_comparison_pdfs
      expect(pdf_file).to eq(IO.binread(expected_file_path))
    rescue RSpec::Expectations::ExpectationNotMetError => e
      File.binwrite(Rails.root.join("tmp", "failed_match_distribution_" + distribution.delivery_method.to_s + "_" + Time.current.to_s + ".pdf"), pdf_file)
      raise e.class, "PDF does not match, written to tmp/", cause: nil
    end
  end

  private def create_comparison_pdf(storage_creation, profile_create_method, expected_file_path, delivery_method)
    partner = create_partner(storage_creation.organization)
    profile = profile_create_method.bind_call(Class.new.extend(DistributionPDFHelper), partner)
    dist = create_dist(partner, storage_creation, delivery_method)
    pdf_file = DistributionPdf.new(storage_creation.organization, dist).compute_and_render
    File.binwrite(expected_file_path, pdf_file)
    profile.destroy!
    dist.request.destroy!
    dist.destroy!
    partner.destroy!
  end

  # helper function that can be called from Rails console to generate comparison PDFs
  def create_comparison_pdfs
    storage_creation = create_organization_storage_items
    file_paths = get_file_paths

    create_comparison_pdf(storage_creation, DistributionPDFHelper.instance_method(:create_profile_no_address), file_paths.expected_pickup_file_path, :pick_up)
    create_comparison_pdf(storage_creation, DistributionPDFHelper.instance_method(:create_profile_without_program_address), file_paths.expected_same_address_file_path, :shipped)
    create_comparison_pdf(storage_creation, DistributionPDFHelper.instance_method(:create_profile_with_program_address), file_paths.expected_different_address_file_path, :delivery)

    storage_creation.storage_location.destroy!
    storage_creation.items[0].destroy!
    storage_creation.items[1].destroy!
    storage_creation.items[2].destroy!
    storage_creation.items[3].destroy!
    storage_creation.organization.destroy!
  end
end

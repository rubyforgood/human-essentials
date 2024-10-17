module DistributionPDFHelper
  def create_profile(program_address1, program_address2, program_city, program_state, program_zip,
    address1 = "Example Address 1", city = "Example City", state = "Example State", zip = "12345")

    create(:partner_profile,
      partner_id: partner.id,
      primary_contact_name: profile_name,
      primary_contact_email: profile_email,
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

  def create_profile_without_program_address
    create_profile("", "", "", "", "")
  end

  def create_profile_with_program_address
    create_profile("Example Program Address 1", "", "Example Program City", "Example Program State", 54321)
  end

  def create_line_items_request(distribution)
    create(:line_item, itemizable: distribution, item: item1, quantity: 50)
    create(:line_item, itemizable: distribution, item: item2, quantity: 100)
    create(:item_unit, item: item4, name: "pack")
    create(:request, :with_item_requests, distribution: distribution,
      request_items: [
        {"item_id" => item2.id, "quantity" => 30},
        {"item_id" => item3.id, "quantity" => 50},
        {"item_id" => item4.id, "quantity" => 120, "request_unit" => "pack"}
])
  end

  def create_dist(delivery_method)
    dist = create(:distribution, partner: partner, delivery_method: delivery_method, issued_at: DateTime.new(2024, 7, 4, 0, 0), organization: organization, storage_location: storage_location)
    create_line_items_request(dist)
    dist
  end

  def compare_pdf(distribution, expected_file_path)
    pdf = DistributionPdf.new(organization, distribution)
    begin
      pdf_file = pdf.compute_and_render

      expect(pdf_file).to eq(IO.binread(expected_file_path))
    rescue RSpec::Expectations::ExpectationNotMetError => e
      File.binwrite(Rails.root.join("tmp", "failed_match_distribution_" + distribution.delivery_method.to_s + "_" + Time.current.to_s + ".pdf"), pdf_file)
      raise e.class, "PDF does not match, written to tmp/", cause: nil
    end
  end

  # helper function you can call from Rails console to create comparison pdfs
  def create_comparison_pdfs
    # create_inventory

    # create_profile no address
    pdf_file = DistributionPdf.new(organization, create_dist(:pickup)).compute_and_render
    File.binwrite(:expected_pickup_file_path, pdf_file)

    # create_profile without_program_address
    pdf_file = DistributionPdf.new(organization, create_dist(:delivery)).compute_and_render
    File.binwrite(:expected_same_address_file_path, pdf_file)

    # create_profile_with_program_address
    pdf_file = DistributionPdf.new(organization, create_dist(:shipped)).compute_and_render
    File.binwrite(:expected_different_address_file_path, pdf_file)
  end
end

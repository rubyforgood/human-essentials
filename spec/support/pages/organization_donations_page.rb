require_relative "organization_page"

class OrganizationDonationsPage < OrganizationPage
  def org_page_path
    # relative path within organization's subtree
    "donations"
  end

  def apply_filter
    click_button "Filter"

    self
  end

  def create_new_donation
    # "New Donation" isn't unique on the page, but this is
    find("a.btn i.fa-plus").click
  end

  def donations_count
    find_all("table tbody tr").count
  end

  def filter_by_donation_site(site_name)
    select site_name, from: "filters_from_donation_site"
    apply_filter
  end

  def filter_by_manufacturer(manufacturer_name)
    select manufacturer_name, from: "filters_from_manufacturer"
    apply_filter
  end

  def filter_by_product_drive(drive_name)
    select drive_name, from: "filters_by_diaper_drive"
    apply_filter
  end

  def filter_by_product_drive_participant(participant_name)
    select participant_name, from: "filters_by_diaper_drive_participant"
    apply_filter
  end

  def filter_by_source(donation_source)
    filter_label = DONATION_SOURCE_FILTER_LABELS.fetch(donation_source) # errors if not present
    select filter_label, from: "filters_by_source"
    apply_filter
  end

  def filter_by_storage_location(location_name)
    select location_name, from: "filters_at_storage_location"
    apply_filter
  end

  private

  # This is essentially Donation.SOURCES from the product code
  # Duplicating it here so that changing this knowledge in the
  # spec realm is a conscious act rather than blindly following
  # a change in the production code
  DONATION_SOURCE_FILTER_LABELS = {
    diaper_drive: "Product Drive",
    manufacturer: "Manufacturer",
    donation_site: "Donation Site",
    misc: "Misc. Donation"
  }
end

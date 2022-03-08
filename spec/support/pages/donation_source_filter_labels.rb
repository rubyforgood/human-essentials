module DonationSourceFilterLables
  private

  # This is essentially Donation.SOURCES from the product code
  # Duplicating it here so that changing this knowledge in the
  # spec realm is a conscious act rather than blindly following
  # (accidental?)change(s) in the production code
  DONATION_SOURCE_FILTER_LABELS = {
    diaper_drive: "Product Drive",
    manufacturer: "Manufacturer",
    donation_site: "Donation Site",
    misc: "Misc. Donation"
  }
end

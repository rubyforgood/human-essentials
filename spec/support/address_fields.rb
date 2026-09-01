# Fills in an address, whatever number of boxes it is spread across.
#
# `Vendor`, `DonationSite`, `ProductDriveParticipant` and `StorageLocation` asked for an address in
# one freeform box until 2026-09-01 and ask for it in four fields now. Eleven examples said
# `fill_in "Address", with: "..."`, and what each of them means is *give this record an address* --
# not *type into one specific box*. Written this way they keep saying that.
#
# It splits with the same `StructuredAddress.parse` the application uses, so a spec cannot pass with
# an address the app would have parsed differently.
module AddressFields
  def fill_in_address(text, within: nil)
    parts = StructuredAddress.parse(text)

    if within
      # Inside a modal the fields are found by id, because two forms with the same labels can be on
      # the page at once -- the donation form and the "new donation site" dialog over it.
      fill_in "#{within}_street", with: parts[:street]
      fill_in "#{within}_city", with: parts[:city]
      select parts[:state], from: "#{within}_state" if parts[:state].present?
      fill_in "#{within}_zipcode", with: parts[:zipcode]
    else
      fill_in "Street address", with: parts[:street]
      fill_in "City", with: parts[:city]
      select parts[:state], from: "State" if parts[:state].present?
      fill_in "ZIP code", with: parts[:zipcode]
    end
  end

  # Empties every part, for the examples that check an address is required.
  def clear_address
    fill_in "Street address", with: ""
    fill_in "City", with: ""
    fill_in "ZIP code", with: ""
  end
end

RSpec.configure { |config| config.include AddressFields, type: :system }

module DonationCreateService
  class << self
    def call(donation)
      if donation.save
        donation.storage_location.increase_inventory(donation.line_item_values)
        DonationEvent.publish(donation)
      end
    end
  end
end

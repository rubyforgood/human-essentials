module DonationCreateService
  class << self
    def call(donation)
      if donation.save
        donation.storage_location.increase_inventory(donation)
        DonationEvent.publish(donation)
      end
    end
  end
end

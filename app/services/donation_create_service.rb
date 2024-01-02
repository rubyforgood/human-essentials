module DonationCreateService
  class << self
    def call(donation)
      Donation.transaction do
        if donation.save
          donation.storage_location.increase_inventory(donation)
          DonationEvent.publish(donation)
        end
      end
    end
  end
end

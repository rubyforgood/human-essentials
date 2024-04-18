module DonationCreateService
  class << self
    def call(donation)
      Donation.transaction do
        unless donation.save
          raise donation.errors.full_messages.join("\n")
        end
        donation.storage_location.increase_inventory(donation.line_item_values)
        DonationEvent.publish(donation)
      end
    end
  end
end

module DonationCreateService
  class << self
    def call(donation)
      Donation.transaction do
        unless donation.save
          raise donation.errors.full_messages.join("\n")
        end
        DonationEvent.publish(donation)
      end
    end
  end
end

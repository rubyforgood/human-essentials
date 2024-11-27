class DonationDestroyService
  attr_reader :error

  def initialize(organization_id:, donation_id:)
    @organization_id = organization_id
    @donation_id = donation_id
  end

  def call
    ActiveRecord::Base.transaction do
      organization = Organization.find(organization_id)
      donation = organization.donations.find(donation_id)
      donation.storage_location.decrease_inventory(donation.line_item_values)
      DonationDestroyEvent.publish(donation)
      donation.destroy!
    end
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "[!] #{self.class.name} failed to destroy donation #{donation_id} because organization or donation does does not exist"
    set_error(e)
  rescue Errors::InsufficientAllotment, InventoryError => e
    Rails.logger.error "[!] #{self.class.name} failed because of Insufficient Allotment"
    set_error(e)
  rescue StandardError => e
    Rails.logger.error "[!] #{self.class.name} failed to destroy donation"
    set_error(e)
  ensure
    return self
  end

  def success?
    error.nil?
  end

  private

  attr_reader :organization_id, :donation_id

  def set_error(error)
    @error = error
  end
end

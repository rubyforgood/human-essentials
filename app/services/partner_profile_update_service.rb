class PartnerProfileUpdateService
  include ServiceObjectErrorsMixin
  attr_reader :error
  def initialize(old_partner, new_partner_params, new_profile_params)
    @partner = old_partner
    @old_profile = old_partner.profile
    @profile = @partner.profile
    @partner_params = new_partner_params
    @old_served_areas = old_partner.profile.served_areas
    @profile_params = new_profile_params
  end

  def call
    @return_value = false
    perform_profile_service do
      @partner.update(@partner_params)
      @return_value = @partner.valid?

      if @return_value
        @profile.served_areas.each(&:destroy!)
        @profile.reload
        @profile.update!(@profile_params)
        @profile.reload
      end
    end
  end

  def perform_profile_service(&block)
    begin
      @profile.transaction do
        yield block
      end
    rescue ActiveRecord::RecordNotFound => e
      Rails.logger.error "[!] #{self.class.name} failed to update profile #{@profile.id} because it does not exist"
      set_error(e)
    rescue => e
      Rails.logger.error "[!] #{self.class.name} failed to update profile for #{@profile.id}: #{@profile.errors.full_messages} [#{e.inspect}]"
      set_error(e)
    end
    self
  end

  def success?
    @error.nil?
  end

  def set_error(error)
    @error = error.to_s
  end
end

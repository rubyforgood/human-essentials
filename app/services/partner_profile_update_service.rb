class PartnerProfileUpdateService
  include ServiceObjectErrorsMixin

  attr_reader :error
  def initialize(old_partner, new_partner_params, new_profile_params)
    @partner = old_partner
    @profile = @partner.profile
    @partner_params = new_partner_params
    @profile_params = new_profile_params
  end

  def call
    return self unless validation

    perform_profile_service do
      @partner.update(@partner_params)
      @profile.served_areas.destroy_all
      @profile.attributes = @profile_params
      @profile.save!(context: :edit)
    end
  end

  def perform_profile_service(&block)
    begin
      @profile.transaction do
        yield block
      end
      @profile.reload
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

  private

  def validation
    return true unless %w[awaiting_review approved].include?(@partner.status)
    return true if @partner.organization.one_step_partner_invite

    check_social_media
    check_mandatory_fields
    @error.nil?
  end

  def check_mandatory_fields
    mandatory_fields = %i[agency_type address1 city state zip_code program_name program_description]
    missing_fields = mandatory_fields.select { |field| @profile_params[field].blank? }
    missing_fields.prepend :agency_name if @partner_params[:name].blank?
    if missing_fields.any?
      @error = "Missing mandatory fields: #{missing_fields.join(', ')}"
    end
  end

  def check_social_media
    social_media_fields = %i[website facebook twitter instagram]
    if social_media_fields.all? { |field| @profile_params[field].blank? } && @profile_params[:no_social_media_presence] == '0'
      @error = "At least one social media field must be filled out or 'No social media presence' must be checked."
    end
  end
end

module Partners
  class RequestApprovalService
    include ServiceObjectErrorsMixin

    # Creates a new instance of Partners::RequestApprovalService
    #
    # @param partner: [Partner] the partner record
    #
    # @return [Partners::RequestApprovalService]
    def initialize(partner:)
      @partner = partner
    end

    def call
      return self unless valid?

      partner.awaiting_review!

      OrganizationMailer.partner_approval_request(organization: partner.organization, partner: partner).deliver_later
      self
    end

    private

    attr_reader :partner

    def valid?
      if partner.status == 'awaiting_review'
        errors.add(:base, 'This partner has already requested approval.')
      end

      unless partner.profile.valid?(:edit)
        errors.add :base, partner.profile.errors.full_messages.join('. ')
      end

      check_social_media
      check_mandatory_fields

      errors.none?
    end

    def check_mandatory_fields
      return if partner.organization.one_step_partner_invite

      mandatory_fields = [
        :agency_type,
        :address1,
        :city,
        :state,
        :zip_code,
        :program_name,
        :program_description
      ]
      messages = []
      messages << "Name can't be blank" if partner.name.blank?
      mandatory_fields.each do |field|
        if partner.profile.send(field).blank?
          messages << "#{field.to_s.humanize.capitalize} can't be blank"
        end
      end
      errors.add(:base, messages.join(", ")) if messages.any?
      errors
    end

    def check_social_media
      return if partner.organization.one_step_partner_invite
      return if partner.profile.website.present? || partner.profile.twitter.present? || partner.profile.facebook.present? || partner.profile.instagram.present?
      return if partner.partials_to_show.exclude?("media_information")

      unless partner.profile.no_social_media_presence
        errors.add(:base, "No social media presence must be checked if you have not provided any of Website, Twitter, Facebook, or Instagram.")
      end
      errors
    end
  end
end

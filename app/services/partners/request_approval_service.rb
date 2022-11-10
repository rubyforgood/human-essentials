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

      partner.profile.update(partner_status: 'submitted')
      partner.awaiting_review!

      OrganizationMailer.partner_approval_request(organization: partner.organization, partner: partner).deliver_later
      self
    end

    private

    attr_reader :partner

    def valid?
      if partner.profile.partner_status == 'submitted'
        errors.add(:base, 'This partner has already requested approval.')
      end

      if partner.profile.has_no_social_media? && partner.profile.no_social_media_presence != true
        errors.add(:base, 'You must either provide a social media site or indicate that you have no social media presence before submitting for approval.')
      end

      errors.none?
    end
  end
end

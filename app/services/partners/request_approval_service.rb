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

      errors.none?
    end
  end
end

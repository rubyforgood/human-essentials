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
        errors.add(:base, 'partner has already requested approval')
      end

      errors.none?
    end
  end
end

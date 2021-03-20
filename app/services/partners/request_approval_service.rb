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

      self
    end

    private

    attr_reader :partner

    def valid?
      if partner.profile.partner_status == 'submitted'
        errors.add(:base, 'partner has already requested approval')
      end

      errors.none?
    end
  end
end

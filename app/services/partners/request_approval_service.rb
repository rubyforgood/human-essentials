module Partners
  class RequestApproval
    include ServiceObjectErrorsMixin

    attr_reader :partner

    def initialize(partner:)
      @partner = partner
    end

    def call
      return self unless valid?

      self
    end

    private

    attr_reader :partner

    def valid?
      if partner.partner_status == 'submitted'
        errors.add(:base, 'partner has already requested approval')
      end

      errors.none?
    end

  end
end

module Partners
  class PartnerForm < Base
    has_one :partner, primary_key: :diaper_bank_id, foreign_key: :diaper_bank_id, dependent: :destroy, inverse_of: :partner_form
    validates :diaper_bank_id, presence: true, uniqueness: true
  end
end

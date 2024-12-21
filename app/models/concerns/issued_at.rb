# Extracts the logic for models that have an `issued_at` field
# This allows DiaperBanks to record a date when the inventory itself was
# issued, which might be different from when the record was last created or manipulated
module IssuedAt
  extend ActiveSupport::Concern

  included do
    scope :by_issued_at, ->(issued_at) { where(issued_at: issued_at.beginning_of_month..issued_at.end_of_month) }
    scope :for_year, ->(year) { where("extract(year from issued_at) = ?", year) }
    validates :issued_at, presence: true
    validate :issued_at_cannot_be_before_2000
    validate :issued_at_cannot_be_further_than_1_year
  end

  private

  def issued_at_cannot_be_before_2000
    if issued_at.present? && issued_at < Date.new(2000, 1, 1)
      errors.add(:issued_at, "cannot be before 2000")
    end
  end

  def issued_at_cannot_be_further_than_1_year
    if issued_at.present? && issued_at > DateTime.now.next_year
      errors.add(:issued_at, "cannot be more than 1 year in the future")
    end
  end
end

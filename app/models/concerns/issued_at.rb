# Extracts the logic for models that have an `issued_at` field
# This allows DiaperBanks to record a date when the inventory itself was
# issued, which might be different from when the record was last created or manipulated
module IssuedAt
  extend ActiveSupport::Concern

  included do
    before_create :initialize_issued_at
    before_save :initialize_issued_at
    scope :by_issued_at, ->(issued_at) { where(issued_at: issued_at.beginning_of_month..issued_at.end_of_month) }
    scope :for_year, ->(year) { where("extract(year from issued_at) = ?", year) }
    validate :issued_at_cannot_be_before_2000
  end

  private

  def initialize_issued_at
    self.issued_at ||= created_at&.end_of_day
  end

  def issued_at_cannot_be_before_2000
    if issued_at.present? && issued_at < Date.new(2000, 1, 1)
      errors.add(:issued_at, "Cannot be before 2000")
    end
  end
end

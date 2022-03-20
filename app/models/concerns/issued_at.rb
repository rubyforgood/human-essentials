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
  end

  private

  def initialize_issued_at
    self.issued_at ||= created_at
  end
end

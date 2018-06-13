module IssuedAt
  extend ActiveSupport::Concern

  included do
    before_create :initialize_issued_at
    scope :by_issued_at, ->(issued_at) { where(issued_at: issued_at.beginning_of_month..issued_at.end_of_month) }
  end

  private

  def initialize_issued_at
    self.issued_at ||= created_at
  end
end

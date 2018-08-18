module IssuedAt
  extend ActiveSupport::Concern

  included do
    scope :by_issued_at, ->(issued_at) { where(issued_at: issued_at.beginning_of_month..issued_at.end_of_month) }
  end
end

module IssuedAt
	extend ActiveSupport::Concern

  included do
    before_create :initialize_issued_at
  end

  private
  def initialize_issued_at
    self.issued_at ||= self.created_at
  end
end

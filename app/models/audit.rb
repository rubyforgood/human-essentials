class Audit < ApplicationRecord
  belongs_to :user
  belongs_to :organization
  belongs_to :adjustment, optional: true

  accepts_nested_attributes_for :adjustment

  enum status: { in_progress: 0, confirmed: 1, finalized: 2 }
end

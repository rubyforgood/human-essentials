class Audit < ApplicationRecord
  belongs_to :user
  belongs_to :organization
  has_one :adjustment, dependent: :nullify
end

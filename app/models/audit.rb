class Audit < ApplicationRecord
  belongs_to :user
  belongs_to :organization
  belongs_to :adjustment, optional: true
end

class Adjustment < ApplicationRecord
  belongs_to :organization
  belongs_to :storage_location
end

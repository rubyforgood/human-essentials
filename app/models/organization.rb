class Organization < ApplicationRecord
  validates :short_name, format: /[a-z0-9_]+/i
end

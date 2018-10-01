class Request < ApplicationRecord
  belongs_to :partner
  belongs_to :organization

  STATUSES = %w[Active Fulfilled].freeze
end

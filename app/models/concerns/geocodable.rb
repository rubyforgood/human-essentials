# Extracts geocoding logic.
module Geocodable
  extend ActiveSupport::Concern
  included do
    geocoded_by :address
    after_validation :geocode, if: ->(obj) { obj.address.present? && obj.address_changed? && !Rails.env.development? }
  end
end
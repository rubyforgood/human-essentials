# == Schema Information
#
# Table name: organizations
#
#  id         :integer          not null, primary key
#  name       :string
#  short_name :string
#  address    :text
#  email      :string
#  url        :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Organization < ApplicationRecord
  validates :name, presence: true
  validates :short_name, presence: true, format: /\A[a-z0-9_]+\z/i
  validates :url, format: /\Ahttps?:\/\//, allow_blank: true
  validates :email, format: /[^@]+@[^@]+/, allow_blank: true

  has_many :adjustments
  has_many :barcode_items
  has_many :distributions
  has_many :donations
  has_many :dropoff_locations
  has_many :storage_locations
  has_many :items
  has_many :partners
  has_many :transfers
  has_many :users

  # NOTE: when finding Organizations, use Organization.find_by(short_name: params[:organization_id])
  def to_param
    short_name
  end

  def address_inline
    address.split("\n").join(",")
  end
end

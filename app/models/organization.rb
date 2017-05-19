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
  validates :short_name, format: /\A[a-z0-9_]+\z/i

  has_many :barcode_items
  has_many :distributions
  has_many :donations
  has_many :dropoff_locations
  has_many :inventories
  has_many :items
  has_many :partners
  has_many :transfers

  # NOTE: when finding Organizations, use Organization.find_by(short_name: params[:organization_id])
  def to_param
    short_name
  end
end

# == Schema Information
#
# Table name: organizations
#
#  id                :integer          not null, primary key
#  name              :string
#  short_name        :string
#  address           :text
#  email             :string
#  url               :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  logo_file_name    :string
#  logo_content_type :string
#  logo_file_size    :integer
#  logo_updated_at   :datetime
#

class Organization < ApplicationRecord
  validates :name, presence: true
  validates :short_name, presence: true, format: /\A[a-z0-9_]+\z/i
  validates :url, format: { with: URI.regexp, message: "it should look like 'http://www.example.com'" }, allow_blank: true
  validates :email, format: /[^@]+@[^@]+/, allow_blank: true
  validates :logo, dimensions: { width: 763, height: 188 }

  has_many :adjustments
  has_many :barcode_items
  has_many :distributions
  has_many :donations
  has_many :dropoff_locations
  has_many :diaper_drive_participants
  has_many :storage_locations
  has_many :inventory_items, through: :storage_locations
  has_many :items
  has_many :partners
  has_many :transfers
  has_many :users

  has_attached_file :logo, default_url: "/DiaperBase-Logo.png"
  validates_attachment_content_type :logo, content_type: /\Aimage\/.*\z/

  # NOTE: when finding Organizations, use Organization.find_by(short_name: params[:organization_id])
  def to_param
    short_name
  end

  def quantity_categories
    storage_locations.map {|i| i.inventory_items}.flatten.group_by{|i| i.item.category}
      .map {|i| [i[0], i[1].map{|i|i.quantity}.sum]}.sort_by { |_, v| -v }
  end

  def address_inline
    address.split("\n").join(",")
  end

  def total_inventory
    inventory_items.map(&:quantity).reduce(:+) || 0
  end
end

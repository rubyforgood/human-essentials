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
#  intake_location   :integer
#  street            :string
#  city              :string
#  state             :string
#  zipcode           :string
#

class Organization < ApplicationRecord
  include Seedable

  validates :name, presence: true
  validates :short_name, presence: true, format: /\A[a-z0-9_]+\z/i
  validates :url, format: { with: URI.regexp, message: "it should look like 'http://www.example.com'" }, allow_blank: true
  validates :email, format: /[^@]+@[^@]+/, allow_blank: true

  has_many :adjustments
  has_many :barcode_items, ->(organization) { unscope(where: :organization_id).where('barcode_items.organization_id = ? OR barcode_items.global = ?', organization.id, true) }
  has_many :distributions
  has_many :donations
  has_many :purchases
  has_many :donation_sites
  has_many :diaper_drive_participants
  has_many :storage_locations
  has_many :inventory_items, through: :storage_locations
  has_many :items
  has_many :partners
  has_many :transfers
  has_many :users

  has_attached_file :logo, styles: { medium: "763x188>", small: "188x188>", thumb: "50x50>"}, default_url: "/DiaperBase-Logo.png"
  validates_attachment_content_type :logo, content_type: /^image\/(jpg|jpeg|pjpeg|png|x-png)$/, message: 'file type is not allowed (only jpeg/png images)'

  after_create { |org| seed_it!(org) }

  # NOTE: when finding Organizations, use Organization.find_by(short_name: params[:organization_id])
  def to_param
    short_name
  end

  def display_users
    users.map {|u| u.email }.join(", ")
  end

  def quantity_categories
    storage_locations.map {|i| i.inventory_items}.flatten.reject{|i| i.item.nil? }.group_by{|i| i.item.category }
      .map {|i| [i[0], i[1].map{|i|i.quantity}.sum]}.sort_by { |_, v| -v }
  end

  def address
    "#{street} #{city}, #{state} #{zipcode}"
  end

  def address_inline
    address.split("\n").map(&:strip).join(", ")
  end

  def total_inventory
    inventory_items.sum(:quantity) || 0
  end

  def scale_values
      {
        pu_2t_3t:   items.find_by(name: "Kids Pull-Ups (2T-3T)").id,
        pu_3t_4t:   items.find_by(name: "Kids Pull-Ups (3T-4T)").id,
        pu_4t_5t:   items.find_by(name: "Kids Pull-Ups (4T-5T)").id,
        k_preemie:  items.find_by(name: "Kids (Preemie)").id,
        k_newborm:  items.find_by(name: "Kids (Newborn)").id,
        k_size1:    items.find_by(name: "Kids (Size 1)").id,
        k_size2:    items.find_by(name: "Kids (Size 2)").id,
        k_size3:    items.find_by(name: "Kids (Size 3)").id,
        k_size4:    items.find_by(name: "Kids (Size 4)").id,
        k_size5:    items.find_by(name: "Kids (Size 5)").id,
        k_size6:    items.find_by(name: "Kids (Size 6)").id,
      }
  end
end

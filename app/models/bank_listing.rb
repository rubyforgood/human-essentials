# == Schema Information
#
# Table name: bank_listings
#
#  id              :bigint           not null, primary key
#  city            :string           not null
#  diapers         :boolean          default(FALSE), not null
#  latitude        :float
#  longitude       :float
#  name            :string           not null
#  name_key        :string           not null
#  period_supplies :boolean          default(FALSE), not null
#  state           :string           not null
#  website         :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  ndbn_member_id  :integer
#
# A diaper or period supply bank in a public directory, for the bank finder.
#
# Not a Human Essentials organization, and not scoped to one: these come from the NDBN member
# directory and the Alliance for Period Supplies' allied programs, and are replaced wholesale by
# BankListingImportService each week. A bank in both directories is one listing with both
# `diapers` and `period_supplies` set. See ADR 0014.
#
# `latitude`/`longitude` are the bank's headquarters *city*, from CensusLocation -- the
# directories give no address -- and are nil for the few cities the Census files do not name.
class BankListing < ApplicationRecord
  validates :name, :name_key, :city, :state, presence: true
  validates :name_key, uniqueness: true

  scope :located, -> { where.not(latitude: nil).where.not(longitude: nil) }

  # "www.example.org/" to "https://www.example.org/". The directories write websites every way.
  def website_url
    return if website.blank?
    website.match?(%r{\Ahttps?://}i) ? website : "https://#{website}"
  end

  # "example.org", for the link text.
  def website_host
    website.to_s.sub(%r{\Ahttps?://}i, "").sub(/\Awww\./i, "").delete_suffix("/").presence
  end

  # "Diapers and period supplies", "Diapers" or "Period supplies".
  def supplies
    [("Diapers" if diapers), ("period supplies" if period_supplies)].compact.join(" and ").upcase_first
  end
end

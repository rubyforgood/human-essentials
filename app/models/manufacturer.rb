# == Schema Information
#
# Table name: manufacturers
#
#  id              :bigint           not null, primary key
#  name            :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :bigint
#

class Manufacturer < ApplicationRecord
  has_paper_trail
  belongs_to :organization

  has_many :donations, inverse_of: :manufacturer, dependent: :destroy

  has_many :line_items, through: :donations

  validates :name, presence: true, uniqueness: { scope: :organization, message: 'Manufacturer already exists' }

  scope :alphabetized, -> { order(:name) }

  scope :with_volumes, -> {
    left_joins(donations: :line_items)
      .select("manufacturers.*, SUM(COALESCE(line_items.quantity, 0)) AS volume")
      .group(:id)
  }

  # The manufacturers who donated something in a period, largest first.
  #
  # **`items_donated`, not `donation_count`.** It is `sum(line_items.quantity)` -- a count of items,
  # not of donations -- and under the old name the report printed it bare, beside a stat labelled
  # "Items donated" holding the same figure. One number, shown twice, named once and wrongly.
  #
  # **Largest first, not most recent.** The page is a summary of who gives most; which period it
  # covers is the date filter's job, and the date is a column of its own now. The old order was
  # `donation_date DESC` and the page showed no dates at all, so the ordering was invisible.
  #
  # `#donating_in_count` is the same set without the limit, so the page can say what it is showing
  # ten of.
  def self.donating_in(date_range, limit: 10)
    donating_in_scope(date_range)
      .select("manufacturers.*, sum(line_items.quantity) as items_donated, max(donations.issued_at) as last_donation_at")
      .order(Arel.sql("sum(line_items.quantity) DESC"))
      .limit(limit)
  end

  def self.donating_in_count(date_range) = donating_in_scope(date_range).count.size

  def self.donating_in_scope(date_range)
    joins(donations: :line_items)
      .where(donations: {issued_at: date_range})
      .group("manufacturers.id")
      .having("sum(line_items.quantity) > 0")
  end
  private_class_method :donating_in_scope
end

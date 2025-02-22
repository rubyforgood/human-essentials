# == Schema Information
#
# Table name: base_items
#
#  id                 :bigint           not null, primary key
#  barcode_count      :integer
#  category           :string
#  item_count         :integer
#  name               :string
#  partner_key        :string
#  reporting_category :string
#  size               :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#

class BaseItem < ApplicationRecord
  has_paper_trail
  has_many :items, dependent: :destroy, inverse_of: :base_item, foreign_key: :partner_key, primary_key: :partner_key
  has_many :barcode_items, as: :barcodeable, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :partner_key, presence: true, uniqueness: true

  scope :by_partner_key, ->(partner_key) { where(partner_key: partner_key) }
  scope :without_kit, -> { where.not(name: 'Kit') }
  scope :alphabetized, -> { order(:name) }

  before_save :set_reporting_category

  OTHER_REPORTING_CATEGORY = "Other"
  NAME_TO_REPORTING_CATEGORY = {
    "Adult Briefs (Large/X-Large)" => "Adult Incontinence",
    "Adult Briefs (Medium/Large)" => "Adult Incontinence",
    "Adult Briefs (Small/Medium)" => "Adult Incontinence",
    "Adult Briefs (XS/Small)" => "Adult Incontinence",
    "Adult Briefs (XXL)" => "Adult Incontinence",
    "Adult Briefs (XXS)" => "Adult Incontinence",
    "Adult Briefs (XXXL)" => "Adult Incontinence",
    "Adult Cloth Diapers (Large/XL/XXL)" => "Adult Incontinence",
    "Adult Cloth Diapers (Small/Medium)" => "Adult Incontinence",
    "Adult Incontinence Pads" => "Adult Incontinence",
    "Bed Pads (Cloth)" => "Other",
    "Bed Pads (Disposable)" => "Other",
    "Bibs (Adult & Child)" => "Other",
    "Cloth Diapers (AIO's/Pocket)" => "Cloth Diapers",
    "Cloth Diapers (Covers)" => "Cloth Diapers",
    "Cloth Diapers (Plastic Cover Pants)" => "Cloth Diapers",
    "Cloth Diapers (Prefolds & Fitted)" => "Cloth Diapers",
    "Cloth Inserts (For Cloth Diapers)" => "Cloth Diapers",
    "Cloth Potty Training Pants/Underwear" => "Cloth Diapers",
    "Cloth Swimmers (Kids)" => "Cloth Diapers",
    "Diaper Rash Cream/Powder" => "Other",
    "Disposable Inserts" => "Disposable diapers",
    "Kids (Newborn)" => "Disposable diapers",
    "Kids (Preemie)" => "Disposable diapers",
    "Kids (Size 1)" => "Disposable diapers",
    "Kids (Size 2)" => "Disposable diapers",
    "Kids (Size 3)" => "Disposable diapers",
    "Kids (Size 4)" => "Disposable diapers",
    "Kids (Size 5)" => "Disposable diapers",
    "Kids (Size 6)" => "Disposable diapers",
    "Kids (Size 7)" => "Disposable diapers",
    "Kids L/XL (60-125 lbs)" => "Disposable diapers",
    "Kids Pull-Ups (2T-3T)" => "Disposable diapers",
    "Kids Pull-Ups (3T-4T)" => "Disposable diapers",
    "Kids Pull-Ups (4T-5T)" => "Disposable diapers",
    "Kids Pull-Ups (5T-6T)" => "Disposable diapers",
    "Kids S/M (38-65 lbs)" => "Disposable diapers",
    "Kit" => nil,
    "Liners (Incontinence)" => "Adult Incontinence",
    "Liners (Menstrual)" => "Menstrual",
    "Other" => "Other",
    "Pads" => "Pads",
    "Swimmers" => "Disposable diapers",
    "Tampons" => "Tampons",
    "Underpads (Pack)" => "Adult Incontinence",
    "Wipes (Adult)" => "Other",
    "Wipes (Baby)" => "Other"
  }.freeze

  def to_h
    { partner_key: partner_key, name: name }
  end

  private

  # Note: Kits have no reporting category.
  def set_reporting_category
    self.reporting_category = NAME_TO_REPORTING_CATEGORY.key?(name) ? NAME_TO_REPORTING_CATEGORY[name] : OTHER_REPORTING_CATEGORY
  end
end

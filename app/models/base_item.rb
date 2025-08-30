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

  OTHER_REPORTING_CATEGORY = "other"
  NAME_TO_REPORTING_CATEGORY = {
    "Adult Briefs (Large/X-Large)" => "adult_incontinence",
    "Adult Briefs (Medium/Large)" => "adult_incontinence",
    "Adult Briefs (Small/Medium)" => "adult_incontinence",
    "Adult Briefs (XS/Small)" => "adult_incontinence",
    "Adult Briefs (XXL)" => "adult_incontinence",
    "Adult Briefs (XXS)" => "adult_incontinence",
    "Adult Briefs (XXXL)" => "adult_incontinence",
    "Adult Cloth Diapers (Large/XL/XXL)" => "adult_incontinence",
    "Adult Cloth Diapers (Small/Medium)" => "adult_incontinence",
    "Adult Incontinence Pads" => "adult_incontinence",
    "Bed Pads (Cloth)" => "other",
    "Bed Pads (Disposable)" => "other",
    "Bibs (Adult & Child)" => "other",
    "Cloth Diapers (AIO's/Pocket)" => "cloth_diapers",
    "Cloth Diapers (Covers)" => "cloth_diapers",
    "Cloth Diapers (Plastic Cover Pants)" => "cloth_diapers",
    "Cloth Diapers (Prefolds & Fitted)" => "cloth_diapers",
    "Cloth Inserts (For Cloth Diapers)" => "cloth_diapers",
    "Cloth Potty Training Pants/Underwear" => "cloth_diapers",
    "Cloth Swimmers (Kids)" => "cloth_diapers",
    "Diaper Rash Cream/Powder" => "other",
    "Disposable Inserts" => "disposable_diapers",
    "Kids (Newborn)" => "disposable_diapers",
    "Kids (Preemie)" => "disposable_diapers",
    "Kids (Size 1)" => "disposable_diapers",
    "Kids (Size 2)" => "disposable_diapers",
    "Kids (Size 3)" => "disposable_diapers",
    "Kids (Size 4)" => "disposable_diapers",
    "Kids (Size 5)" => "disposable_diapers",
    "Kids (Size 6)" => "disposable_diapers",
    "Kids (Size 7)" => "disposable_diapers",
    "Kids L/XL (60-125 lbs)" => "disposable_diapers",
    "Kids Pull-Ups (2T-3T)" => "disposable_diapers",
    "Kids Pull-Ups (3T-4T)" => "disposable_diapers",
    "Kids Pull-Ups (4T-5T)" => "disposable_diapers",
    "Kids Pull-Ups (5T-6T)" => "disposable_diapers",
    "Kids S/M (38-65 lbs)" => "disposable_diapers",
    "Kit" => nil,
    "Liners (Incontinence)" => "adult_incontinence",
    "Liners (Menstrual)" => "period_liners",
    "Other" => "other",
    "Pads" => "pads",
    "Swimmers" => "disposable_diapers",
    "Tampons" => "tampons",
    "Underpads (Pack)" => "adult_incontinence",
    "Wipes (Adult)" => "other",
    "Wipes (Baby)" => "other"
  }.freeze

  def to_h
    { partner_key: partner_key, name: name, reporting_category: reporting_category }
  end

  private

  # Note: Kits have no reporting category.
  def set_reporting_category
    self.reporting_category = NAME_TO_REPORTING_CATEGORY.key?(name) ? NAME_TO_REPORTING_CATEGORY[name] : OTHER_REPORTING_CATEGORY
  end
end

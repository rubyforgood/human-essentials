class Request < ApplicationRecord
  belongs_to :partner
  belongs_to :organization
  belongs_to :distribution, optional: true

  scope :active, -> { where(status: "Active") }

  STATUSES = %w[Active Fulfilled].freeze

  DIAPERMAPPING = {
    "adult_lxl" => "Adult Briefs (Large/X-Large)",
    "adult_ml" => "Adult Briefs (Medium/Large)",
    "adult_sm" => "Adult Briefs (Small/Medium)",
    "adult_xxl" => "Adult Briefs (XXL)",
    "cloth" => "Cloth Diapers (Plastic Cover Pants)",
    "disposable_inserts" => "Disposable Inserts",
    "k_newborn" => "Kids (Newborn)",
    "k_preemie" => "Kids (Preemie)",
    "k_size1" => "Kids (Size 1)",
    "k_size2" => "Kids (Size 2)",
    "k_size3" => "Kids (Size 3)",
    "k_size4" => "Kids (Size 4)",
    "k_size5" => "Kids (Size 5)",
    "k_size6" => "Kids (Size 6)",
    "k_lxl" => "Kids L/XL (60-125 lbs)",
    "pullup_23t" => "Kids Pull-Ups (2T-3T)",
    "pullup_34t" => "Kids Pull-Ups (3T-4T)",
    "pullup_45t" => "Kids Pull-Ups (4T-5T)",
    "k_sm" => "Kids S/M (38-65 lbs)",
    "swimmers" => "Swimmers",
    "adult_cloth_lxl" => "Adult Cloth Diapers (Large/XL/XXL)",
    "adult_cloth_sm" => "Adult Cloth Diapers (Small/Medium)",
    "cloth_aio" => "Cloth Diapers (AIO's/Pocket)",
    "cloth_cover" => "Cloth Diapers (Covers)",
    "cloth_prefold" => "Cloth Diapers (Prefolds & Fitted)",
    "cloth_insert" => "Cloth Inserts (For Cloth Diapers)",
    "cloth_swimmer" => "Cloth Swimmers (Kids)",
    "adult_incontinence" => "Adult Incontinence Pads",
    "underpads" => "Underpads (Pack)",
    "bed_pad_cloth" => "Bed Pads (Cloth)",
    "bed_pad_disposable" => "Bed Pads (Disposable)",
    "bib" => "Bibs (Adult & Child)",
    "diaper_rash_cream" => "Diaper Rash Cream/Powder",
    "cloth_training_pants" => "Cloth Potty Training Pants/Underwear",
    "wipes" => "Wipes (Baby)"
  }.freeze
end

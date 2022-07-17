# == Schema Information
#
# Table name: partner_forms
#
#  id                 :bigint           not null, primary key
#  sections           :text             default([]), is an Array
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  essentials_bank_id :integer
#
module Partners
  class PartnerForm < Base
    has_one :partner, primary_key: :essentials_bank_id, foreign_key: :essentials_bank_id, dependent: :destroy, inverse_of: :partner_form
    validates :essentials_bank_id, presence: true, uniqueness: true
  end
end

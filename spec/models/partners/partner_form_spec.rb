# == Schema Information
#
# Table name: partner_forms
#
#  id             :bigint           not null, primary key
#  sections       :text             default([]), is an Array
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  diaper_bank_id :integer
#
require "rails_helper"

RSpec.describe Partners::PartnerForm, type: :model, skip_seed: true do
  describe 'associations' do
    it { should have_one(:partner).with_primary_key(:diaper_bank_id).with_foreign_key(:diaper_bank_id) }
  end

  describe 'validations' do
    it { should validate_presence_of(:diaper_bank_id) }
    it { should validate_uniqueness_of(:diaper_bank_id) }
  end
end




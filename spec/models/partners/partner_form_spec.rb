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
require "rails_helper"

RSpec.describe Partners::PartnerForm, type: :model do
  describe 'associations' do
    it { should have_one(:partner).with_primary_key(:essentials_bank_id).with_foreign_key(:essentials_bank_id) }
  end

  describe 'validations' do
    it { should validate_presence_of(:essentials_bank_id) }
    it { should validate_uniqueness_of(:essentials_bank_id) }
  end
end




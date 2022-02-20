# == Schema Information
#
# Table name: ndbn_members
#
#  account_name   :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  ndbn_member_id :bigint           not null, primary key
#
require 'rails_helper'

RSpec.describe NDBNMember, type: :model do

  describe 'validations' do
    subject { build(:ndbn_member) }
    it { should validate_presence_of(:ndbn_member_id) }
    it { should validate_presence_of(:account_name) }
    it { should validate_uniqueness_of(:ndbn_member_id) }
  end


end

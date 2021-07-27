# == Schema Information
#
# Table name: authorized_family_members
#
#  id            :bigint           not null, primary key
#  comments      :text
#  date_of_birth :date
#  first_name    :string
#  gender        :string
#  last_name     :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  family_id     :bigint
#
require "rails_helper"

RSpec.describe Partners::AuthorizedFamilyMember, type: :model do
  describe 'associations' do
    it { should belong_to(:family) }
    it { should have_many(:child_item_requests).dependent(:nullify) }
  end
end



# == Schema Information
#
# Table name: taggings
#
#  id            :bigint           not null, primary key
#  taggable_type :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  tag_id        :bigint           not null
#  taggable_id   :bigint           not null
#
RSpec.describe Tagging, type: :model do
  describe "assocations" do
    it { should belong_to(:tag) }
    it { should belong_to(:taggable) }
  end
end

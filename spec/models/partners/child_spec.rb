require "rails_helper"

RSpec.describe Partners::Child, type: :model do
  describe 'associations' do
    it { should belong_to(:family) }
    it { should have_many(:child_item_requests).dependent(:destroy) }
  end
end

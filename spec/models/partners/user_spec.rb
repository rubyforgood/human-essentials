require "rails_helper"

RSpec.describe Partners::User, type: :model do

  describe 'associations' do
    it { should belong_to(:partner) }
    # TODO make this spec work.
    # it { should have_many(:requests).class_name('Partners::Request').with_foreign_key(:partner_id).dependent(:destroy) }
  end

end

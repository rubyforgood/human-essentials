require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe 'confirm_delete_msg' do
    let(:item) { 'Adult Briefs (Medium/Large)' }

    it "subs in string" do
      expect(helper.confirm_delete_msg(item)).to include(item)
    end
  end
end

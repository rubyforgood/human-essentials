require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "confirm_delete_msg" do
    let(:item) { "Adult Briefs (Medium/Large)" }

    it "subs in string" do
      expect(helper.confirm_delete_msg(item)).to include(item)
    end
  end

  describe "step_container_helper" do
    context "active_index is equal to index" do
      let(:active_index) { 1 }
      let(:index) { 1 }

      it "returns active" do
        expect(helper.step_container_helper(index, active_index)).to include("active")
      end
    end

    context "active_index is greater than index" do
      let(:active_index) { 2 }
      let(:index) { 1 }

      it "returns done" do
        expect(helper.step_container_helper(index, active_index)).to include("done")
      end
    end

    context "active_index is less than index" do
      let(:active_index) { 0 }
      let(:index) { 1 }

      it "returns empty string" do
        expect(helper.step_container_helper(index, active_index)).to eq("")
      end
    end
  end
end

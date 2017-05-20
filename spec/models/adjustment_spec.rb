require 'rails_helper'

RSpec.describe Adjustment, type: :model do
  context "Validations >" do
    it "must belong to an organization" do
      expect(build(:adjustment, organization_id: nil)).not_to be_valid
    end
  end
end

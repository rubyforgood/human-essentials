# == Schema Information
#
# Table name: containers
#
#  id              :integer          not null, primary key
#  quantity        :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  item_id         :integer
#  itemizable_id   :integer
#  itemizable_type :string
#



RSpec.describe Container, type: :model do
	context "Validations >" do
		it "requires an item" do
			expect(build(:container, item: nil)).not_to be_valid
		end

		it "requires a quantity" do
			expect(build(:container, quantity: nil)).not_to be_valid
		end
	end
end

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

require "rails_helper"

RSpec.describe Container, type: :model do
	let(:container) { FactoryGirl.create :container }
	it "has a quantity" do
		expect(container.quantity).to_not be nil
	end
	it "does not allow a quantity to not be present" do
		container = Container.new(quantity: nil)
		expect(container.valid?).to be false
	end
end

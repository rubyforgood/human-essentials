require 'rails_helper'

describe Partners::FamilyRequestCreateService do
  describe '#call' do
    subject { described_class.new(args).call }
    let(:args) do
      {
        partner_user_id: partner_user.id,
        family_requests_attributes: family_requests_attributes
      }
    end
    let(:partner_user) { partner.primary_partner_user }
    let(:partner) { create(:partner) }

    context 'when the arguments are incorrect' do
      context 'because no family_requests_attributes were defined' do
        let(:family_requests_attributes) { [] }

        it 'should return the Partners::FamilyRequestCreateService object with an error' do
          result = subject

          expect(result).to be_a_kind_of(Partners::FamilyRequestCreateService)
          expect(result.errors[:base]).to eq(["family_requests_attributes cannot be empty"])
        end
      end

      context 'because a unrecognized item_id was provided' do
        let(:family_requests_attributes) do
          [
            ActionController::Parameters.new(item_id: 0, person_count: Faker::Number.within(range: 1..10))
          ]
        end

        it 'should return the Partners::FamilyRequestCreateService object with an error' do
          result = subject

          expect(result).to be_a_kind_of(Partners::FamilyRequestCreateService)
          expect(result.errors[:base]).to eq(["detected a unknown item_id"])
        end
      end
    end

    context 'when the arguments are correct' do
      let(:items_to_request) { partner_user.partner.organization.items.all.sample(2) }
      let(:first_item_id) { items_to_request.first.id.to_i }
      let(:second_item_id) { items_to_request.second.id.to_i }
      let(:child1) { create(:partners_child) }
      let(:child2) { create(:partners_child) }
      let(:family_requests_attributes) do
        [
          {
            item_id: first_item_id,
            person_count: 1,
            children: [child1]
          },
          {
            item_id: second_item_id,
            person_count: 2,
            children: [child1, child2]
          }
        ]
      end

      it 'should create the appropriate organization ::Request, Partners::Request, Partners::ItemRequest and Partners::ChildItemRequests' do
        expect do
          subject
        end.to change { ::Request.count }
          .by(1)
          .and change { Partners::Request.count }
          .by(1)

        expect(::Request.last.request_items.map { |item| item["item_id"] }).to match_array(items_to_request.pluck(:id))

        partner_request = Partners::Request.last
        expect(partner_request.item_requests.count).to eq(2)

        first_item_request = partner_request.item_requests.find_by(item_id: first_item_id)
        expect(first_item_request.children).to contain_exactly(child1)

        second_item_request = partner_request.item_requests.find_by(item_id: second_item_id)
        expect(second_item_request.children).to contain_exactly(child1, child2)
      end
    end
  end
end

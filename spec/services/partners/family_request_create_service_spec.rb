RSpec.describe Partners::FamilyRequestCreateService do
  describe '#call' do
    subject { described_class.new(**args).call }
    let(:args) do
      {
        partner_user_id: partner_user.id,
        comments: comments,
        for_families: for_families,
        family_requests_attributes: family_requests_attributes
      }
    end
    let(:organization) { create(:organization) }
    let(:partner) { create(:partner, organization: organization) }
    let(:partner_user) { partner.primary_user }
    let(:comments) { Faker::Lorem.paragraph }
    let(:for_families) { false }

    context 'when the arguments are incorrect' do
      context 'because no family_requests_attributes or comments were defined' do
        let(:family_requests_attributes) { [] }
        let(:comments) { '' }

        it 'should return the Partners::FamilyRequestCreateService object with an error' do
          result = subject

          expect(result).to be_a_kind_of(Partners::FamilyRequestCreateService)
          expect(result.errors[:base]).to eq(["completely empty request"])
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

    context 'when the arguments are correct and org has items' do
      let(:organization) { create(:organization, :with_items) }

      context 'with children' do
        let(:items_to_request) { partner_user.partner.organization.items.all.sample(2) }
        let(:first_item_id) { items_to_request.first.id.to_i }
        let(:second_item_id) { items_to_request.second.id.to_i }
        let(:child1) { create(:partners_child) }
        let(:child2) { create(:partners_child) }
        let(:child3) { create(:partners_child) }
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
            },
            {
              item_id: second_item_id,
              person_count: 2,
              children: [child1, child3]
            }
          ]
        end

        it 'should create the appropriate organization Request, Partners::ItemRequest and Partners::ChildItemRequests' do
          expect do
            subject
          end.to change { Request.count }
            .by(1)

          expect(Request.last.request_items.map { |item| item["item_id"] }).to match_array(items_to_request.pluck(:id))

          partner_request = Request.last
          expect(partner_request.item_requests.count).to eq(2)

          first_item_request = partner_request.item_requests.find_by(item_id: first_item_id)
          expect(first_item_request.children).to contain_exactly(child1)

          second_item_request = partner_request.item_requests.find_by(item_id: second_item_id)
          # testing the de-duping logic of request create service
          expect(second_item_request.children).to contain_exactly(child1, child2, child3)
          expect(second_item_request.children.count).to eq(3)

          expect(first_item_request.quantity.to_i).to eq(first_item_request.item.default_quantity)
          expect(second_item_request.quantity.to_i).to eq(second_item_request.item.default_quantity * 4)
        end
      end

      context 'without children' do
        let(:items_to_request) { partner_user.partner.organization.items.all.sample(3) }
        let(:family_requests_attributes) do
          items_to_request.map do |item|
            ActionController::Parameters.new(
              item_id: item.id,
              person_count: Faker::Number.within(range: 1..10)
            )
          end
        end
        let(:expected_item_request_attributes) do
          family_requests_attributes.map do |fr_attr|
            {
              item_id: fr_attr[:item_id],
              quantity: Item.find(fr_attr[:item_id]).default_quantity * fr_attr[:person_count],
              children: nil
            }
          end
        end
        let(:fake_request_create_service) { instance_double(Partners::RequestCreateService, call: -> {}, errors: [], partner_request: -> {}) }

        before do
          allow(Partners::RequestCreateService).to receive(:new).with(partner_user_id: partner_user.id, comments: comments, for_families: false, item_requests_attributes: contain_exactly(*expected_item_request_attributes)).and_return(fake_request_create_service)
        end

        it 'should send the correct request payload to the Partners::RequestCreateService and call it' do
          subject
          expect(fake_request_create_service).to have_received(:call)
        end
      end
    end
  end
end

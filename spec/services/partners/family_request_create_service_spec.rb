require 'rails_helper'

describe Partners::FamilyRequestCreateService do
  describe '#call' do
    subject { described_class.new(args).call }
    let(:args) do
      {
        partner_user_id: partner_user.id,
        comments: comments,
        family_requests_attributes: family_requests_attributes
      }
    end
    let(:partner_user) { partner.primary_partner_user }
    let(:partner) { create(:partner) }
    let(:comments) { Faker::Lorem.paragraph }
    let(:family_requests_attributes) do
      [
        ActionController::Parameters.new(
          item_id: FactoryBot.create(:item).id,
          person_count: Faker::Number.within(range: 1..10)
        ),
        ActionController::Parameters.new(
          item_id: FactoryBot.create(:item).id,
          person_count: Faker::Number.within(range: 1..10)
        )
      ]
    end

    context 'when the arguments are incorrect' do
      context 'because no family_requests_attributes were defined' do
        let(:family_requests_attributes) { [] }

        it 'should return the Partners::FamilyRequestCreateService object with an error' do
          result = subject

          expect(result).to be_a_kind_of(Partners::FamilyRequestCreateService)
          expect(result.errors[:base]).to eq(["family_requests_attributes cannot be empty"])
        end
      end

      context 'because a unrecogonized item_id was provided' do
        let(:family_requests_attributes) do
          [
            ActionController::Parameters.new({
              item_id: 0,
              person_count: Faker::Number.within(range: 1..10)
            })
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
            quantity: Item.find(fr_attr[:item_id]).default_quantity * fr_attr[:person_count]
          }
        end
      end
      let(:fake_request_create_service) { instance_double(Partners::RequestCreateService, call: -> {}, errors: []) }

      before do
        allow(Partners::RequestCreateService).to receive(:new).with(partner_user_id: partner_user.id, comments: comments, item_requests_attributes: contain_exactly(*expected_item_request_attributes)).and_return(fake_request_create_service)
      end

      it 'should send the correct request payload to the Partners::RequestCreateService and call it' do
        subject
        expect(fake_request_create_service).to have_received(:call)
      end
    end
  end
end


RSpec.describe Partners::RequestCreateService do
  describe '#call' do
    subject { described_class.new(**args).call }
    let(:args) do
      {
        partner_user_id: partner_user.id,
        comments: comments,
        item_requests_attributes: item_requests_attributes
      }
    end
    let(:partner_user) { partner.primary_user }
    let(:partner) { create(:partner) }
    let(:comments) { Faker::Lorem.paragraph }
    let(:item_requests_attributes) do
      [
        ActionController::Parameters.new(
          item_id: FactoryBot.create(:item).id,
          quantity: Faker::Number.within(range: 1..10)
        )
      ]
    end

    context 'when the arguments are incorrect' do
      context 'because no item_requests_attributes and comments were defined' do
        let(:item_requests_attributes) { [] }
        let(:comments) { "" }

        it 'should return the Request object with an error' do
          result = subject

          expect(result).to be_a_kind_of(Partners::RequestCreateService)
          expect(result.errors[:base]).to eq(["completely empty request"])
        end
      end

      context 'because a unrecogonized item_id was provided' do
        let(:item_requests_attributes) do
          [
            ActionController::Parameters.new(
              item_id: 0,
              quantity: Faker::Number.within(range: 1..10)
            )
          ]
        end

        it 'should return the Request object with an error' do
          result = subject

          expect(result).to be_a_kind_of(Partners::RequestCreateService)
          expect(result.errors[:"item_requests.name"]).to eq(["can't be blank"])
        end
      end
    end

    context 'when the arguments are correct' do
      let(:items_to_request) { BaseItem.all.sample(3) }
      let(:fake_organization_valid_items) do
        items_to_request.map do |item|
          {
            id: item.id,
            partner_key: item.partner_key,
            name: item.name
          }
        end
      end

      before do
        allow(Organization).to receive(:find_by).with(id: partner_user.partner.organization_id).and_return(
          double(Organization, valid_items: fake_organization_valid_items)
        )
        allow(NotifyPartnerJob).to receive(:perform_now)
      end

      it 'should have no errors' do
        expect(subject.errors).to be_empty
      end

      it 'should create a Request record' do
        expect { subject }.to change { Request.count }.by(1)
      end

      it 'should notify the Partner via email' do
        subject
        expect(NotifyPartnerJob).to have_received(:perform_now).with(Request.last.id)
      end

      it 'should have created item requests' do
        subject
        expect(Partners::ItemRequest.count).to eq(item_requests_attributes.count)
      end

      context 'when we have duplicate item as part of request' do
        let(:duplicate_item) { FactoryBot.create(:item) }
        let(:unique_item) { FactoryBot.create(:item) }
        let(:item_requests_attributes) do
          [
            ActionController::Parameters.new(
              item_id: duplicate_item.id,
              quantity: 3
            ),
            ActionController::Parameters.new(
              item_id: unique_item.id,
              quantity: 7
            ),
            ActionController::Parameters.new(
              item_id: duplicate_item.id,
              quantity: 5
            )
          ]
        end
        it 'should add the quantity of the duplicate item' do
          subject
          aggregate_failures {
            expect(Partners::ItemRequest.count).to eq(2)
            expect(Partners::ItemRequest.find_by(item_id: duplicate_item.id).quantity).to eq("8")
            expect(Partners::ItemRequest.find_by(item_id: unique_item.id).quantity).to eq("7")
            expect(Partners::ItemRequest.first.item_id).to eq(duplicate_item.id)
          }
        end
      end

      context 'but a unexpected error occured during the save' do
        let(:error_message) { 'boom' }

        context 'for the Request record' do
          before do
            allow_any_instance_of(Request).to receive(:save!).and_raise(error_message)
          end

          it 'should have an error with the raised error' do
            expect(subject.errors[:base]).to eq([error_message])
          end

          it 'should NOT create a Request record' do
            expect { subject }.not_to change { Request.count }
          end

          it 'should NOT notify the Partner via email' do
            subject
            expect(NotifyPartnerJob).not_to have_received(:perform_now)
          end
        end
      end
    end
  end
end

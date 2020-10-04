require 'rails_helper'


describe KitCreateService do

  describe '#call' do
    subject { described_class.new(args).call }
    let(:args) do
      {
        organization_id: organization_id,
        kit_params: kit_params
      }
    end
    let(:organization_id) { FactoryBot.create(:organization).id }
    let(:kit_params) do
      attrs = FactoryBot.attributes_for(:kit)
      attrs.merge!({line_items_attributes: line_items_attr})
      attrs
    end

    let(:line_items_attr) do
      FactoryBot.create_list(:line_item, 3).map do |line_item|
        {
          item_id: line_item.id,
          quantity: Faker::Number.number(digits: 2)
        }
      end
    end

    it 'should return an the instance' do
      expect(subject).to be_a_kind_of(described_class)
    end

    context 'when the parameters are valid' do
      it 'should create a new Kit' do
        expect { subject }.to change { Kit.all.count }.by(1)
      end

      it 'should create a new Item' do
        expect { subject }.to change { Item.all.count }.by(1)
      end

      it 'should create the new Item associated with the Kit' do
        subject
        expect(Kit.last.item).not_to eq(nil)
      end

      context 'but an unexpected error gets raised' do
        let(:raised_error) { 'boom' }
        before do
          allow_any_instance_of(ItemCreateService).to receive(:call).and_raise(raised_error)
        end

        it 'should not create the Kit' do
          expect { subject }.not_to change { Kit.all.count }
        end

        it 'should not create a Item' do
          expect { subject }.not_to change { Item.all.count }
        end

        it 'should have an error that includes the raised error' do
          expect(subject.errors[:base]).to eq([raised_error])
        end
      end
    end

    context 'when the parameters provided are invalid' do
      context 'because the organization_id does not match any Organization' do
        let(:organization_id) { 0 }

        it 'should have an error on organization_id saying it does not match any Organization' do
          expect(subject.errors[:organization_id]).to eq(['does not match any Organization'])
        end
      end

      context 'because the kit_params is invalid for kit creation' do
        let(:kit_params) { { organization_id: organization_id } }
        let(:kit_validation_errors) do
          kit = Kit.new(kit_params)
          kit.valid?
          kit.errors
        end

        it 'should have errors saying why the kit_params are invalid' do
          expect(subject.errors.full_messages.map(&:humanize)).to eq(kit_validation_errors.full_messages)
        end
      end
    end
  end
end

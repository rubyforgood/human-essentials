require "rails_helper"

RSpec.describe UiHelper, type: :helper do
  describe 'optional_data_text' do
    subject { helper.optional_data_text(field) }

    context 'when the field provided is not blank' do
      let(:field) { Faker::Name.first_name }

      it 'should return the content' do
        expect(subject).to match(/span/m)
        expect(subject).to include(field)
      end
    end

    context 'when the field provided is blank' do
      let(:field) { '' }

      it 'should return the text Not-Provided in gray text' do
        expect(subject).to match(/span/m)
        expect(subject).to include('Not-Provided')
        expect(subject).to include('text-muted font-weight-light')
      end
    end
  end
end


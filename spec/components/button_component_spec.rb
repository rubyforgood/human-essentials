# frozen_string_literal: true

require "rails_helper"

RSpec.describe ButtonComponent, type: :component do

  describe 'button' do
    subject { render_inline(described_class.new(label: label)) }
    let(:label) { 'Click me' }

    it 'should include the label' do
      expect(subject.text).to include(label)
    end
  end

end

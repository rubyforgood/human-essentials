# frozen_string_literal: true

require "rails_helper"

RSpec.describe AuthenticationLayoutComponent, type: :component do
  subject { render_inline(described_class.new(side_image_path:  side_image_path)) }
  let(:side_image_path) { 'https://via.placeholder.com/300x300' }

  it 'should have the logo component' do
    expect(subject.text).to include('Human Essentials')
  end

  it 'should have the image with the src set to the side_image_path' do
    expect(subject.css('img').first.attributes['src'].value).to eq(side_image_path)
  end

end

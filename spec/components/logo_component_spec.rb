# frozen_string_literal: true

require "rails_helper"

RSpec.describe LogoComponent, type: :component do
  subject { render_inline(described_class.new) }

  it "should have the human essentials text" do
    expect(subject.text).to include("Human Essentials")
  end
end

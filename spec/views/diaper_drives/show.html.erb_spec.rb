require 'rails_helper'

RSpec.describe "diaper_drives/show", type: :view do
  before(:each) do
    @diaper_drive = assign(:diaper_drive, DiaperDrive.create!(
      :name => "Name",
      :start_date => Time.now
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Name/)
  end
end

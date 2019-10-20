require 'rails_helper'

RSpec.describe "diaper_drives/edit", type: :view do
  before(:each) do
    @diaper_drive = assign(:diaper_drive, DiaperDrive.create!(
      :name => "MyString",
      :start_date => Time.now
    ))
  end

  it "renders the edit diaper_drive form" do
    render

    assert_select "form[action=?][method=?]", diaper_drive_path(@diaper_drive), "post" do

      assert_select "input[name=?]", "diaper_drive[name]"
    end
  end
end

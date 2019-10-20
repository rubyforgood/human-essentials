require 'rails_helper'

RSpec.describe "diaper_drives/new", type: :view do
  before(:each) do
    assign(:diaper_drive, DiaperDrive.new(
      :name => "MyString"
    ))
  end

  it "renders new diaper_drive form" do
    render

    assert_select "form[action=?][method=?]", diaper_drives_path, "post" do

      assert_select "input[name=?]", "diaper_drive[name]"
    end
  end
end

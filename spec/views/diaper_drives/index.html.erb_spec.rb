require 'rails_helper'

RSpec.describe "diaper_drives/index", type: :view do
  before(:each) do
    assign(:diaper_drives, [
      DiaperDrive.create!(
        :name => "Name",
        :start_date => Time.now
      ),
      DiaperDrive.create!(
        :name => "Name",
        :start_date => Time.now
      )
    ])
  end

  it "renders a list of diaper_drives" do
    render
    assert_select "tr>td", :text => "Name".to_s, :count => 2
  end
end

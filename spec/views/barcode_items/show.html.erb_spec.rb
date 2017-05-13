

RSpec.describe "barcode_items/show.html.erb", type: :view do
  before(:each) do
  	@barcode_item = create(:barcode_item)
    assign(:barcode_item, @barcode_item)
    render
  end

  it "shows the name, quantity, and barcode value for the barcode" do
    expect(rendered).to have_content(@barcode_item.item.name)
    expect(rendered).to have_content(@barcode_item.quantity)
    expect(rendered).to have_content(@barcode_item.value)
  end

end

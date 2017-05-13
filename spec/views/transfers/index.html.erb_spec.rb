

RSpec.describe "transfers/index.html.erb", type: :view do
  before(:each) do
  	t1 = create(:transfer, comment: "MOVES STUFF", from: create(:inventory, name: "From1"), to: create(:inventory, name: "To1"))
  	t1.containers << create(:container, quantity: 10)
  	t1.containers << create(:container, quantity: 20)

  	t2 = create(:transfer)
  	t2.containers << create(:container)

    assign(:transfers, Transfer.all)

  	render
  end

  it "shows a table with all the transfers" do
  	expect(rendered).to have_xpath("//table[@id='transfers']/tbody/tr", count: 2)
  end

  it "shows the inventory names, total moved, and the comment" do
  	expect(rendered).to have_xpath("//table[@id='transfers']/tbody/tr/td", text: "From1")
  	expect(rendered).to have_xpath("//table[@id='transfers']/tbody/tr/td", text: "To1")
  	expect(rendered).to have_xpath("//table[@id='transfers']/tbody/tr/td", text: "30")
  	expect(rendered).to have_xpath("//table[@id='transfers']/tbody/tr/td", text: "MOVES STUFF")
  end
end

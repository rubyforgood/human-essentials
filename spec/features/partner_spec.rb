RSpec.feature "Partner management", type: :feature do
  let!(:url_prefix) { "/#{@organization.to_param}"}
  scenario "User can add a new partner" do
  	visit url_prefix + '/partners/new'
    fill_in "Name", with: "Frank"
    fill_in "E-mail", with: "frank@frank.com"
    click_button "Create Partner"

    expect(page.find('.flash.success')).to have_content "added"
  end

  scenario "User can update a partner" do
    partner = create(:partner, name: "Frank")
    visit url_prefix + "/partners/#{partner.id}/edit"
    fill_in "Name", with: "Franklin"
    click_button "Update Partner"

    expect(page.find('.flash.success')).to have_content "updated"
    partner.reload
    expect(partner.name).to eq('Franklin')
  end

end
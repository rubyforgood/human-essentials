RSpec.describe "NDBN Members Upload", type: :system do
  it "CSV upload flow functions without error" do
    user = create(:super_admin)
    sign_in(user)
    visit admin_ndbn_members_path

    import_path = "#{Rails.root}/spec/fixtures/ndbn-small-import.csv"
    attach_file("member_file", import_path)
    click_button "Upload"

    expect(page).to have_content("NDBN Members have been updated!")
  end
end

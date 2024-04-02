RSpec.describe "NDBN Members Upload", type: :system do
  # TODO: This test crashes right after the upload
  xit "CSV upload flow functions without error" do
    user = create(:super_admin)
    sign_in(user)
    visit admin_ndbn_members_path

    attach_file("member_file", "spec/fixtures/ndbn-large-import.csv")
    click_button "Upload"

    expect(page).to have_content("NDBN Members have been updated!")
  end
end

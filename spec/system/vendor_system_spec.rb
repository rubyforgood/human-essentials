RSpec.describe "Vendor", type: :system, js: true do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }

  before do
    sign_in(user)
  end

  context "When a user views the index page" do
    before(:each) do
      @second = create(:vendor, business_name: "Bcd")
      @first = create(:vendor, business_name: "Abc")
      @third = create(:vendor, business_name: "Cde")
      visit vendors_path
    end

    it "should have the vendor names in alphabetical order" do
      expect(page).to have_xpath("//table//tr", count: 4)
      expect(page.find(:xpath, "//table/tbody/tr[1]/td[1]")).to have_content(@first.business_name)
      expect(page.find(:xpath, "//table/tbody/tr[3]/td[1]")).to have_content(@third.business_name)
    end

    it "should deactivate a vendor when the deactivate button is clicked" do
      expect { click_link "Deactivate", match: :first }.to change { @first.reload.active }.to(false)
    end

    it "should reactivate a vendor when the reactivate button is clicked" do
      expect { click_link "Deactivate", match: :first }.to change { @first.reload.active }.to(false)

      check "include_inactive_vendors"
      click_button "Filter"

      expect { click_link "Reactivate", match: :first }.to change { @first.reload.active }.to(true)
    end

    context "When using the include_inactive_vendors filter" do
      before(:each) do
        @active_vendor = create(:vendor, business_name: "Active Vendor", active: true)
        @inactive_vendor = create(:vendor, business_name: "Inactive Vendor", active: false)
        visit vendors_path
      end

      it "shows inactive vendors when the filter is applied" do
        check "include_inactive_vendors"
        click_button "Filter"

        expect(page).to have_content(@active_vendor.business_name)
        expect(page).to have_content(@inactive_vendor.business_name)
      end
    end
  end

  context "when creating a new vendor" do
    subject { new_vendor_path }

    it "can create a new vendor instance as a user" do
      visit subject
      vendor_traits = attributes_for(:vendor)
      fill_in "Contact Name", with: vendor_traits[:contact_name]
      fill_in "Business Name", with: vendor_traits[:business_name]
      fill_in "Phone", with: vendor_traits[:phone]

      expect do
        click_button "Save"
      end.to change { Vendor.count }.by(1)

      expect(page.find(".alert")).to have_content "added"
    end

    it "cannot add a new vendor instance with empty attributes" do
      visit subject
      click_button "Save"

      expect(page.find(".alert")).to have_content "didn't work"
    end
  end

  context "when editing an existing vendor" do
    let!(:vendor) { create(:vendor) }
    subject { edit_vendor_path(vendor.id) }
    it "can update the contact info for a vendor as a user" do
      new_email = "foo@bar.com"
      visit subject
      fill_in "Phone", with: ""
      fill_in "E-mail", with: new_email
      click_button "Save"

      expect(page.find(".alert")).to have_content "updated"
      expect(page).to have_content(vendor.contact_name)
      expect(page).to have_content(new_email)
    end

    it "does not update a vendor with empty attributes" do
      visit subject
      fill_in "Business Name", with: ""
      fill_in "Contact Name", with: ""
      click_button "Save"

      expect(page.find(".alert")).to have_content "didn't work"
    end
  end

  context "When vendor have purchases associated with them already" do
    before(:each) do
      @vendor = create(:vendor)
      create(:purchase, :with_items, created_at: 1.day.ago, item_quantity: 10, amount_spent_in_cents: 1, vendor: @vendor)
      create(:purchase, :with_items, created_at: 1.week.ago, item_quantity: 15, amount_spent_in_cents: 1, vendor: @vendor)
    end

    it "can have existing vendors show in the #index with some summary stats" do
      visit vendors_path
      expect(page).to have_xpath("//table/tbody/tr/td", text: @vendor.business_name)
      expect(page).to have_xpath("//table/tbody/tr/td", text: "25")
    end

    it "can have a single vendor show semi-detailed stats about purchases" do
      visit vendor_path(@vendor.to_param)
      expect(page).to have_xpath("//table/tbody/tr", count: 3)
      expect(page).to have_xpath("//table/tbody/tr/td", text: "10")
    end
  end
end

require "rails_helper"

# Specs in this file have access to a helper object that includes
# the PurchasesHelper. For example:
#
# describe PurchasesHelper do
#   describe "string concat" do
#     it "concats two strings with spaces" do
#       expect(helper.concat_strings("this","that")).to eq("this that")
#     end
#   end
# end
RSpec.describe PartnersHelper, type: :helper, skip_seed: true do
  # pending "add some examples to (or delete) #{__FILE__}"
  it "returns a generated path" do
    path_string = "/#{@organization.short_name}/organization"
    expect(helper.documentation_url(organization_path(@organization))).to eq path_string
  end
end

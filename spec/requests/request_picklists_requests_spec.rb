# Printing picklists for the requests the reader selected.
#
# `print_unfulfilled` prints everything outstanding; this prints the picked set, which is the case
# that used to mean opening each row's menu in turn. See design.md, Selection.
RSpec.describe "Batch picklists", type: :request do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }

  before { sign_in user }

  let!(:one) { create(:request, organization: organization) }
  let!(:two) { create(:request, organization: organization) }

  it "renders a PDF for the selected requests" do
    get print_picklists_requests_path(format: :pdf, ids: [one.id, two.id])

    expect(response).to be_successful
    expect(response.header["Content-Type"]).to include("application/pdf")
    expect(response.body).to start_with("%PDF")
  end

  it "says so rather than rendering an empty PDF when nothing is selected" do
    get print_picklists_requests_path(format: :pdf)

    expect(response).to redirect_to(requests_path)
    expect(flash[:alert]).to eq("Select at least one request to print picklists for.")
  end

  it "ignores an id belonging to another organization" do
    # Scoped through `current_organization.requests`, so a guessed id selects nothing rather than
    # leaking another bank's picklist.
    other = create(:request, organization: create(:organization))

    get print_picklists_requests_path(format: :pdf, ids: [other.id])

    expect(response).to redirect_to(requests_path)
    expect(flash[:alert]).to be_present
  end
end

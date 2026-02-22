RSpec.describe DonationSitesController, type: :controller do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }

  context "While signed in" do
    before do
      sign_in(user)
    end

    describe "GET #index" do
      subject { get :index }
      it "returns http success" do
        expect(subject).to be_successful
      end
    end

    describe "GET #new" do
      subject { get :new }
      it "returns http success" do
        expect(subject).to be_successful
      end
    end

    describe "GET #edit" do
      subject { get :edit, params: { id: create(:donation_site, organization: organization) } }
      it "returns http success" do
        expect(subject).to be_successful
      end
    end

    describe "POST #import_csv" do
      let(:model_class) { DonationSite }
      it_behaves_like "csv import"
    end

    describe "GET #show" do
      subject { get :show, params: { id: create(:donation_site, organization: organization) } }
      it "returns http success" do
        expect(subject).to be_successful
      end
    end
  end
end

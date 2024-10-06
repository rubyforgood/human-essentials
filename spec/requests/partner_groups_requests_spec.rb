RSpec.describe PartnerGroupsController, type: :request do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let!(:category_item) { create(:item_category, organization: organization, name: "Test Item") }
  let!(:category_item2) { create(:item_category, organization: organization, name: "Another Test Item") }

  context "While signed in" do
    before do
      sign_in(user)
    end

    describe "GET #new" do
      subject { get new_partner_group_path }

      it "renders the new template and assigns variables correctly" do
        get new_partner_group_path

        expect(response).to render_template(:new)
        expect(assigns(:partner_group)).to be_a_new(PartnerGroup)
        expect(assigns(:item_categories)).to eq([category_item, category_item2])
        expect(response.body).to include("Test Item")
        expect(response.body).to include("Another Test Item")
      end
    end

    describe "POST #create" do
      let(:attributes) { nil }

      subject { post partner_groups_path, params: {partner_group: attributes} }

      context "with valid attributes" do
        let(:attributes) { attributes_for(:partner_group, organization_id: organization.id, name: "partner group") }

        it "creates a new partner group" do
          expect { subject }.to change(PartnerGroup, :count).by(1)
          expect(PartnerGroup.last.name).to eq("partner group")
        end

        it "redirects to the partners path" do
          expect(subject).to redirect_to(partners_path + "#nav-partner-groups")
        end
      end

      context "with invalid attributes" do
        let(:attributes) { {name: "existing_partner"} }
        let!(:partner_group) { create(:partner_group, organization: organization, name: "existing_partner") }

        it "does not create a new partner group" do
          expect { subject }.not_to change(PartnerGroup, :count)
        end

        it "re-renders the new template with assigned values" do
          expect(subject).to render_template(:new)
          expect(assigns(:partner_group)).to be_a_new(PartnerGroup)
          expect(assigns(:item_categories)).to eq([category_item, category_item2])
          expect(subject).to have_error("Something didn't work quite right -- try again?")
          expect(response.body).to include("Test Item")
          expect(response.body).to include("Another Test Item")
        end
      end
    end

    describe "GET #edit" do
      let(:partner_group) { create(:partner_group, organization: organization) }

      subject { get edit_partner_group_path(partner_group) }

      it "renders the edit template and assigns variables correctly" do
        get edit_partner_group_path(partner_group)

        expect(response).to render_template(:edit)
        expect(assigns(:partner_group)).to eq(partner_group)
        expect(assigns(:item_categories)).to eq([category_item, category_item2])
        expect(response.body).to include("Test Item")
        expect(response.body).to include("Another Test Item")
      end
    end

    describe "PATCH #update" do
      let(:partner_group) { create(:partner_group, organization: organization) }
      let(:attributes) { nil }

      subject { patch partner_group_path(partner_group), params: {partner_group: attributes} }

      context "with valid attributes" do
        let(:attributes) { {name: "new name"} }

        it "updates the partner group" do
          expect { subject }.to change { partner_group.reload.name }.from(partner_group.name).to("new name")
        end

        it "redirects to the partners path" do
          expect(subject).to redirect_to(partners_path + "#nav-partner-groups")
        end
      end

      context "with invalid attributes" do
        let(:attributes) { {name: nil} }

        it "does not update the partner group" do
          expect { subject }.not_to change { partner_group.reload.name }
        end

        it "re-renders the edit template with assigned values" do
          expect(subject).to render_template(:edit)
          expect(assigns(:partner_group)).to eq(partner_group)
          expect(assigns(:item_categories)).to eq([category_item, category_item2])
          expect(subject).to have_error("Something didn't work quite right -- try again?")
          expect(response.body).to include("Test Item")
          expect(response.body).to include("Another Test Item")
        end
      end
    end
  end

  context "While not signed in" do
    let(:object) { create(:partner_group, organization: organization) }

    include_examples "requiring authorization"
  end
end

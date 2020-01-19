RSpec.describe TransfersController, type: :controller do
  context "While signed in" do
    before do
      sign_in(@user)
    end

    describe "GET #index" do
      around do |example|
        travel_to Time.zone.local(2019, 7, 1)
        example.run
        travel_back
      end

      subject { get :index, params: { organization_id: @organization.short_name } }
      it "returns http success" do
        expect(subject).to be_successful
      end

      context 'when filtering by date' do
        let!(:old_transfer) { create(:transfer, created_at: 7.days.ago) }
        let!(:new_transfer) { create(:transfer, created_at: 1.day.ago) }

        context 'when date parameters are supplied' do
          it 'only returns the correct obejects' do
            start_date = 3.days.ago.strftime "%m/%d/%Y"
            end_date = Time.zone.today.strftime "%m/%d/%Y"
            get :index, params: { organization_id: @organization.short_name, filters: { date_range: "#{start_date} - #{end_date}" } }
            expect(assigns(:transfers)).to eq([new_transfer])
          end
        end

        context 'when date parameters are not supplied' do
          it 'returns all objects' do
            get :index, params: { organization_id: @organization.short_name }
            expect(assigns(:transfers)).to eq([old_transfer, new_transfer])
          end
        end
      end
    end

    describe "POST #create" do
      it "redirects to #show when successful" do
        attributes = attributes_for(
          :transfer,
          organization_id: @organization.id,
          to_id: create(:storage_location, organization: @organization).id,
          from_id: create(:storage_location, organization: @organization).id
        )

        post :create, params: { organization_id: @organization.short_name, transfer: attributes }
        expect(response).to redirect_to(transfers_path)
      end

      it "renders to #new when failing" do
        post :create, params: { organization_id: @organization.short_name, transfer: { from_id: nil, to_id: nil } }
        expect(response).to be_successful # Will render :new
        expect(response).to render_template("new")
        expect(response).to have_error(/error/i)
      end
    end

    describe "GET #new" do
      subject { get :new, params: { organization_id: @organization.short_name } }
      it "returns http success" do
        expect(subject).to be_successful
      end
    end

    describe "GET #show" do
      subject { get :show, params: { organization_id: @organization.short_name, id: create(:transfer, organization: @organization) } }
      it "returns http success" do
        expect(subject).to be_successful
      end
    end

    describe "GET #edit" do
      subject { get :edit, params: { organization_id: @organization.short_name, id: transfer.id } }

      context 'when the transfer belongs to the organization' do
        let(:transfer) { create(:transfer, organization: @organization) }

        it "returns http success" do
          expect(subject).to be_successful
        end

        it "should assign the transfer, storage locations, and items" do
          subject
          expect(assigns[:transfer]).to eq(transfer)
          expect(assigns[:storage_locations]).to eq(@organization.storage_locations.alphabetized)
          expect(assigns[:items]).to eq(@organization.items.active.alphabetized)
        end
      end

      context 'when the transfer does not belong to the organization' do
        let(:transfer) { create(:transfer, organization: create(:organization)) }

        it "returns http not successful" do
          expect(subject).not_to be_successful
        end
      end
    end

    describe 'PATCH #update' do
      subject { patch :update, params: { organization_id: @organization.short_name, id: transfer.id, transfer: transfer_params } }
      let(:transfer_params) { attributes_for(:transfer, organization_id: @organization.id, to_id: create(:storage_location, organization: @organization).id.to_s, from_id: create(:storage_location, organization: @organization).id.to_s) }

      context 'when the transfer belongs to the organization' do
        let(:transfer) { create(:transfer, organization: @organization) }
        let(:fake_organization_transfers) { instance_double('Transfer::ActiveRecord_Associations_CollectionProxy') }

        before do
          allow(controller.current_organization).to receive(:transfers).and_return(
            fake_organization_transfers
          )
          allow(fake_organization_transfers).to receive(:find).with(transfer.id.to_s).and_return(
            transfer
          )
          expect(transfer).to receive(:assign_attributes).with(
            ActionController::Parameters.new(transfer_params).permit(
              :from_id, :to_id, :comment, line_items_attributes: %i(item_id quantity _destroy)
            )
          )
        end

        context 'and the update is successful' do
          let(:fake_from) { instance_double(StorageLocation, decrease_inventory: -> {}, name: 'fake-from-name') }
          let(:fake_to) { instance_double(StorageLocation, increase_inventory: -> {}, name: 'fake-to-name')}

          before do
            allow(transfer).to receive(:valid?).and_return(true)
            allow(transfer).to receive(:save).and_return(true)
            allow(transfer).to receive(:from).and_return(fake_from)
            allow(transfer).to receive(:to).and_return(fake_to)
          end

          it 'should save the record and update inventories' do
            subject
            expect(transfer).to have_received(:save)
            expect(fake_from).to have_received(:decrease_inventory).with(transfer)
            expect(fake_to).to have_received(:increase_inventory).with(transfer)
          end
        end

        context 'but the update was not valid' do
          before do
            allow(transfer).to receive(:valid?).and_return(false)
          end

          it 'should redirect to the edit page with and error message' do
            subject
            expect(flash[:error]).to match(/There was an error updating the transfer/)
            expect(response).to redirect_to(edit_transfer_path(transfer.id))
          end
        end
      end

      context 'when the transfer does not belong to the organization' do
        let(:transfer) { create(:transfer, organization: create(:organization)) }

        it "returns http not successful" do
          expect(subject).not_to be_successful
        end
      end
    end

    context "Looking at a different organization" do
      let(:object) do
        org = create(:organization)
        create(:transfer,
               to: create(:storage_location, organization: org),
               from: create(:storage_location, organization: org),
               organization: org)
      end
      include_examples "requiring authorization", except: %i(edit update destroy)
    end
  end

  context "While not signed in" do
    let(:object) { create(:transfer) }

    include_examples "requiring authorization", except: %i(edit update destroy)
  end
end

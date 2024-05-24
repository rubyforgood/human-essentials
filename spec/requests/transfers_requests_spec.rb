RSpec.describe "Transfers", type: :request do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }

  context "While signed in" do
    before do
      sign_in(user)
    end

    describe "GET #index" do
      subject do
        get transfers_path(format: response_format)
        response
      end

      around do |example|
        travel_to Time.zone.local(2019, 7, 1)
        example.run
        travel_back
      end

      context "html" do
        let(:response_format) { 'html' }

        it { is_expected.to be_successful }

        context 'when filtering by date' do
          let!(:old_transfer) { create(:transfer, created_at: 7.days.ago, organization: organization) }
          let!(:new_transfer) { create(:transfer, created_at: 1.day.ago, organization: organization) }

          context 'when date parameters are supplied' do
            it 'only returns the correct obejects' do
              start_date = 3.days.ago.to_formatted_s(:date_picker)
              end_date = Time.zone.today.to_formatted_s(:date_picker)
              get transfers_path(filters: { date_range: "#{start_date} - #{end_date}" })
              expect(assigns(:transfers)).to eq([new_transfer])
            end
          end

          context 'when date parameters are not supplied' do
            it 'returns all objects' do
              get transfers_path
              expect(assigns(:transfers)).to eq([old_transfer, new_transfer])
            end
          end
        end
      end

      context "csv" do
        let(:response_format) { 'csv' }

        it { is_expected.to be_successful }
      end
    end

    describe "POST #create" do
      it "redirects to #index when successful" do
        attributes = attributes_for(
          :transfer,
          organization_id: organization.id,
          to_id: create(:storage_location, organization: organization).id,
          from_id: create(:storage_location, organization: organization).id
        )

        expect { post transfers_path(transfer: attributes) }
          .to change { Transfer.count }.by(1)
          .and change { TransferEvent.count }.by(1)
        expect(response).to redirect_to(transfers_path)
      end

      it "renders to #new when failing" do
        post transfers_path(transfer: { from_id: nil, to_id: nil })
        expect(response).to be_successful # Will render :new
        expect(response).to render_template("new")
        expect(flash.keys).to match_array(['error'])
      end
    end

    describe "GET #new" do
      subject { get new_transfer_path }
      it "returns http success" do
        subject
        expect(response).to be_successful
      end
    end

    describe "GET #show" do
      subject { get transfer_path(id: create(:transfer, organization: organization)) }
      it "returns http success" do
        subject
        expect(response).to be_successful
      end
    end

    describe 'DELETE #destroy' do
      let(:transfer_id) { create(:transfer, organization: organization).id.to_s }
      let(:fake_destroy_service) { instance_double(TransferDestroyService) }
      subject { delete transfer_path(id: transfer_id) }
      before do
        allow(TransferDestroyService).to receive(:new).with(transfer_id: transfer_id).and_return(fake_destroy_service)
      end

      context 'when the transfer destroy service was successful' do
        let(:fake_success_struct) { OpenStruct.new(success?: true) }

        before do
          allow(fake_destroy_service).to receive(:call).and_return(fake_success_struct)
          subject
        end

        it 'should set a notice flash with the success message and redirect to index' do
          expect(flash[:notice]).to eq("Succesfully deleted Transfer ##{transfer_id}!")
          expect(response).to redirect_to(transfers_path)
        end
      end

      context 'when the transfer destroy service was not successful' do
        let(:fake_error_struct) { OpenStruct.new(success?: false, error: fake_error) }
        let(:fake_error) { StandardError.new('fake-error-msg') }

        before do
          allow(fake_destroy_service).to receive(:call).and_return(fake_error_struct)
          subject
        end

        it 'should set a error flash with the error message and redirect to index' do
          expect(flash[:error]).to eq(fake_error.message)
          expect(response).to redirect_to(transfers_path)
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
      include_examples "requiring authorization", except: %i(edit update)
    end
  end

  context "While not signed in" do
    let(:object) { create(:transfer) }

    include_examples "requiring authorization", except: %i(edit update)
  end
end

require 'rails_helper'

RSpec.describe "ProductDrives", type: :request, skip_seed: true do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:default_params) { { organization_id: organization.to_param } }

  context "while not signed in" do
    it "is unsuccessful" do
      get product_drives_path(default_params)

      expect(response).not_to be_successful
    end
  end

  context "While signed in >" do
    before do
      sign_in(user)
    end

    describe "GET #index" do
      subject { get product_drives_path(default_params) }

      it "returns http success" do
        subject

        expect(response).to be_successful
      end

      it 'displays only product drives that belong to organization and that match drive name and date range' do
        filter_params = {
          date_range: date_range_picker_params(Date.parse('20/01/2000'), Date.parse('22/01/2000')),
          by_name: "AAAA"
        }
        default_params[:filters] = filter_params

        product_drive = create(:product_drive, organization: organization, name: "AAAA", start_date: '20/01/2000', end_date: '22/01/2000')

        product_drive_two = create(:product_drive, organization: organization, name: "BBBB", start_date: '20/01/2000', end_date: '22/01/2000')
        product_drive_three = create(:product_drive, organization: create(:organization), name: "AAAA", start_date: '20/01/2000', end_date: '22/01/2000')
        product_drive_four = create(:product_drive, organization: organization, name: "AAAA", start_date: '20/01/1990', end_date: '22/01/1990')
        product_drive_five = create(:product_drive, organization: organization, name: "AAAA", start_date: '20/01/2022', end_date: '22/01/2022')

        subject

        expect(response).to be_successful

        expect(response.body).to include(product_drive_path(product_drive.id))

        expect(response.body).not_to include(product_drive_path(product_drive_two.id))
        expect(response.body).not_to include(product_drive_path(product_drive_three.id))
        expect(response.body).not_to include(product_drive_path(product_drive_four.id))
        expect(response.body).not_to include(product_drive_path(product_drive_five.id))
      end

      context "csv" do
        before { default_params.merge!(format: :csv) }

        it 'is successful' do
          subject

          expect(response).to be_successful
          expect(response.header['Content-Type']).to include 'text/csv'

          expected_headers = "Product Drive Name,Start Date,End Date,Held Virtually?,Quantity of Items,Variety of Items,In Kind Value\n"
          expect(response.body).to eq(expected_headers)
        end

        it 'returns ONLY the associated product drives' do
          create(:product_drive, name: 'product_drive', organization: organization)
          create(:product_drive, name: 'unassociated_product_drive', organization: create(:organization))

          subject

          expect(response.body).to include('product_drive')
          expect(response.body).not_to include('unassociated_product_drive')
        end

        it 'returns ONLY the product drives within a selected date range (inclusive)' do
          default_params[:filters] = { date_range: date_range_picker_params(Date.parse('30/01/1979'), Date.parse('30/01/1982')) }

          create(
            :product_drive,
            name: 'early_product_drive',
            start_date: '30/01/1970',
            end_date: '30/01/1971',
            organization: organization
          )
          create(
            :product_drive,
            name: 'product_drive_within_date_range',
            start_date: '30/01/1980',
            end_date: '30/01/1981',
            organization: organization
          )
          create(
            :product_drive,
            name: 'product_drive_on_date_range',
            start_date: '30/01/1979',
            end_date: '30/01/1982',
            organization: organization
          )

          create(
            :product_drive,
            name: 'late_product_drive',
            start_date: '30/01/1990',
            end_date: '30/01/1991',
            organization: organization
          )

          subject

          expect(response.body).to include('product_drive_within_date_range')
          expect(response.body).to include('product_drive_on_date_range')
          expect(response.body).not_to include('early_product_drive')
          expect(response.body).not_to include('late_product_drive')
        end
      end
    end

    describe "GET #new" do
      it "returns http success" do
        get new_product_drive_path(default_params)
        expect(response).to be_successful
      end
    end

    describe "POST#create" do
      it "returns redirect http status" do
        post product_drives_path(default_params.merge(product_drive: attributes_for(:product_drive)))
        expect(response).to have_http_status(:redirect)
      end
    end

    describe "PUT#update" do
      it "returns redirect http status" do
        product_drive = create(:product_drive, organization: organization)

        put product_drive_path(default_params.merge(id: product_drive.id, product_drive: attributes_for(:product_drive)))
        expect(response).to have_http_status(:redirect)
      end
    end

    describe "GET #edit" do
      it "returns http success" do
        product_drive = create(:product_drive, organization: organization)

        get edit_product_drive_path(default_params.merge(id: product_drive.id))
        expect(response).to be_successful
      end
    end

    describe "GET #show" do
      it "returns http success" do
        product_drive = create(:product_drive, organization: organization)

        get product_drive_path(default_params.merge(id: product_drive.id))
        expect(response).to be_successful
      end
    end

    describe "DELETE #destroy" do
      it "redirects to the index" do
        product_drive = create(:product_drive, organization: organization)

        delete product_drive_path(default_params.merge(id: product_drive.id))
        expect(response).to redirect_to(product_drives_path)
      end
    end
  end
end

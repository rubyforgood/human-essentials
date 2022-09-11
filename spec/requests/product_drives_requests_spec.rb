require 'rails_helper'

RSpec.describe "ProductDrives", type: :request, skip_seed: true do
  let(:organization) { FactoryBot.create(:organization) }
  let(:user) { FactoryBot.create(:user, organization: organization) }
  let(:default_params) { { organization_id: organization.to_param } }

  context "while not signed in" do
    it "is unsuccessful" do
      get product_drives_path(default_params)

      expect(response).not_to be_successful
    end
  end

  context "While signed in >" do
    let(:product_drive) { create(:product_drive, organization: organization) }
    before do
      sign_in(user)
    end

    describe "GET #index" do
      subject { get product_drives_path(default_params) }

      it "returns http success" do
        subject

        expect(response).to be_successful
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
          FactoryBot.create(:product_drive, name: 'product_drive', organization: organization)
          FactoryBot.create(:product_drive, name: 'unassociated_product_drive', organization: FactoryBot.create(:organization))

          subject

          expect(response.body).to include('product_drive')
          expect(response.body).not_to include('unassociated_product_drive')
        end

        it 'returns ONLY the product drives within a selected date range (inclusive)' do
          default_params.merge!(filters: { date_range: date_range_picker_params(Date.parse('30/01/1979'), Date.parse('30/01/1982')) })

          FactoryBot.create(
            :product_drive,
            name: 'early_product_drive',
            start_date: '30/01/1970',
            end_date: '30/01/1971',
            organization: organization
          )
          FactoryBot.create(
            :product_drive,
            name: 'product_drive_within_date_range',
            start_date: '30/01/1980',
            end_date: '30/01/1981',
            organization: organization
          )
          FactoryBot.create(
            :product_drive,
            name: 'product_drive_on_date_range',
            start_date: '30/01/1979',
            end_date: '30/01/1982',
            organization: organization
          )

          FactoryBot.create(
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
        put product_drive_path(default_params.merge(id: product_drive.id, product_drive: attributes_for(:product_drive)))
        expect(response).to have_http_status(:redirect)
      end
    end

    describe "GET #edit" do
      it "returns http success" do
        get edit_product_drive_path(default_params.merge(id: product_drive.id))
        expect(response).to be_successful
      end
    end

    describe "GET #show" do
      it "returns http success" do
        get product_drive_path(default_params.merge(id: product_drive.id))
        expect(response).to be_successful
      end
    end

    describe "DELETE #destroy" do
      it "redirects to the index" do
        delete product_drive_path(default_params.merge(id: product_drive.id))
        expect(response).to redirect_to(product_drives_path)
      end
    end
  end
end

require 'rails_helper'

RSpec.describe "/partners/requests", type: :request do
  describe "GET #index" do
    subject { -> { get partners_requests_path } }
    let(:partner_user) { partner.primary_user }
    let(:partner) { create(:partner) }

    before do
      sign_in(partner_user)
    end

    it 'should render without any issues' do
      subject.call
      expect(response).to render_template(:index)
    end
  end

  describe "GET #new" do
    subject { -> { get new_partners_request_path } }
    let(:partner_user) { partner.primary_user }
    let(:partner) { create(:partner) }

    before do
      sign_in(partner_user)
    end

    it 'should render without any issues' do
      subject.call
      expect(response).to render_template(:new)
    end
  end

  describe "GET #shows" do
    # TODO: write this spec
    # Ensure to cover that:
    # - Authorization, other partners should not be able to see this
    # - Ensure it shows 404 if the partner request id doesn't exist
  end

  describe "POST #create" do
    subject { -> { post partners_requests_path, params: { request: request_attributes } } }
    let(:request_attributes) do
      {
        comments: Faker::Lorem.paragraph,
        item_requests_attributes: {
          "0" => {
            item_id: Item.all.sample.id,
            quantity: Faker::Number.within(range: 4..13)
          }
        }
      }
    end
    let(:partner_user) { partner.primary_user }
    let(:partner) { create(:partner) }

    before do
      sign_in(partner_user)
    end

    context 'when given valid parameters' do
      let(:request_attributes) do
        {
          comments: Faker::Lorem.paragraph,
          item_requests_attributes: {
            "0" => {
              item_id: Item.all.sample.id,
              quantity: Faker::Number.within(range: 4..13)
            }
          }
        }
      end

      it 'should redirect to the show page' do
        subject.call
        expect(response).to redirect_to(partners_request_path(Request.last.id))
      end
    end

    context 'when given invalid parameters' do
      let(:request_attributes) do
        {
          comments: ""
        }
      end

      it 'should not redirect' do
        subject.call
        expect(response).to render_template(:new)
      end
    end
  end
end

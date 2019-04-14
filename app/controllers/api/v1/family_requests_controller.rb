class API::V1::FamilyRequestsController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_user!
  skip_before_action :authorize_user
  respond_to :json

  def create
    return head :forbidden unless api_key_valid?

    partner_request = parse_request
    if partner_request.save
      render json: partner_request.family_request_reply, status: :created
    else
      render json: partner_request.errors, status: :bad_request
    end
  end

  private

  def api_key_valid?
    request.headers["X-Api-Key"] == ENV["PARTNER_KEY"]
  end

  def parse_request
    Request.parse_family_request(request_params)
  end

  def request_params
    JSON.parse(request.body.read)
  end
end

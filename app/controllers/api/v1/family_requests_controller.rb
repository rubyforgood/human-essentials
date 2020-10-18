# Family Requests are an alternate approach to direct inventory requests. Instead of requesting literal items,
# the Partner indicates who is in the family, and then the organization determines (automatically, through the
# Magic of Technology(TM)) how much inventory should be dispensed to that family, via that Partner.
class API::V1::FamilyRequestsController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_user!
  skip_before_action :authorize_user
  respond_to :json

  def create
    return head :forbidden unless api_key_valid?

    partner_request = parse_request

    if partner_request.save
      NotifyPartnerJob.perform_now(partner_request.id)
      render json: partner_request.family_request_reply, status: :created
    else
      render json: partner_request.errors, status: :bad_request
    end
  rescue Request::MismatchedItemIdsError => e
    render json: { message: e.message }, status: :bad_request
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

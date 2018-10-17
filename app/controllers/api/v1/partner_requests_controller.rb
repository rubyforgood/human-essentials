class API::V1::PartnerRequestsController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_user!
  skip_before_action :authorize_user
  respond_to :json

  def create
    return head :forbidden unless api_key_valid?
    request = Request.new(request_params)
    if request.save
      render json: request, status: :created
    else
      render json: request.errors, status: :bad_request
    end
  end

  private

  def api_key_valid?
    request.headers["X-Api-Key"] == ENV["PARTNER_KEY"]
  end

  def request_params
    params.require(:request).permit(:organization_id, :partner_id, :comments,
                                    request_items: CanonicalItem.pluck(:partner_key).map(&:to_sym))
  end
end

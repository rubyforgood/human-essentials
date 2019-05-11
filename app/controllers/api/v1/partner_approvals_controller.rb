# All Partners must be approved before they can begin submitting Requests. This is done over the API.
class API::V1::PartnerApprovalsController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_user!
  skip_before_action :authorize_user
  respond_to :json

  def create
    return head :forbidden unless api_key_valid?

    @partner = Partner.find(approval_params[:diaper_partner_id])
    @partner.awaiting_review!
    render json: { message: "Status changed to awaiting review." }, status: :ok
  end

  private

  def approval_params
    params.require(:partner).permit(:diaper_partner_id)
  end

  def api_key_valid?
    return true if Rails.env.development?

    request.headers["X-Api-Key"] == ENV["PARTNER_KEY"]
  end
end

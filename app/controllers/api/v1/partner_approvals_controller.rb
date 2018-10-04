class API::V1::PartnerApprovalsController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_user!
  skip_before_action :authorize_user
  respond_to :json

  def create
    return head :forbidden unless api_key_valid?
    @partner = Partner.find(params[:partner])
    @partner.update(status: "Awaiting Review")
    render json: { message: "Status changed to awaiting review." }, status: :ok
  end

  private

  def api_key_valid?
    request.headers["X-Api-Key"] == ENV["PARTNER_KEY"]
  end
end

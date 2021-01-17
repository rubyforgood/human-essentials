# Creates the primary channel through which Partners submit requests, which occurs via the API
class API::V1::PartnerRequestsController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_user!
  skip_before_action :authorize_user
  respond_to :json

  def create
    return head :forbidden unless api_key_valid?

    request = Request.new(request_params)

    if request.save
      NotifyPartnerJob.perform_now(request.id)
      render json: request, status: :created
    else
      render json: request.errors, status: :bad_request
    end
  end

  def show
    return head :forbidden unless api_key_valid?

    items = PartnerRequestableItemsService.new(organization_id: params[:id], partner_id: params[:partner_id]).call
    render json: items, status: :ok
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: e.message }, status: :bad_request
  end

  private

  def api_key_valid?
    return true if Rails.env.development?

    request.headers["X-Api-Key"] == ENV["PARTNER_KEY"]
  end

  def request_params
    params.require(:request).permit(:organization_id, :partner_id, :comments,
                                    request_items: [:item_id, :quantity])
  end
end

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
                                    request_items: %i[adult_xxl adult_lxl adult_ml
                                                      adult_sm cloth disposable_inserts k_newborn
                                                      k_preemie k_size1 k_size2 k_size3 k_size4 k_size5
                                                      k_size6 k_sm k_lxl pullup_23t pullup_34t
                                                      pullup_45t swimmers adult_cloth_lxl adult_cloth_sm
                                                      cloth_aio cloth_cover cloth_prefold cloth_insert
                                                      cloth_swimmer adult_incontinence underpads
                                                      bed_pad_cloth bed_pad_disposable bib
                                                      diaper_rash_cream cloth_training_pants wipes])
  end
end

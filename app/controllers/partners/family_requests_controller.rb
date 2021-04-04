class FamilyRequestsController < ApplicationController
  before_action :authenticate_user!
  before_action :verify_status_in_diaper_base
  before_action :authorize_verified_partners

  def new
    @filterrific = initialize_filterrific(
      current_partner.children
          .order(last_name: :asc)
          .order(first_name: :asc),
      params[:filterrific]
    ) || return
    @children = @filterrific.find
  end

  def create
    children = current_partner.children.active.where.not(item_needed_diaperid: [nil, 0])
    request = FamilyRequestPayloadService.execute(children: children, partner: current_partner)

    FamilyRequestService.execute(request)

    redirect_to partner_requests_path, notice: "Requested items successfuly!"
  rescue ActiveModel::ValidationError
    render :new
  end
end

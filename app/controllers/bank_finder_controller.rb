# The public bank finder: someone who wants diapers or period supplies types where they are, and
# gets the nearest banks from the NDBN and Alliance for Period Supplies directories. Linked from
# /account_requests/new, because organizations looking for supplies kept requesting a bank
# account instead. Signed out, on the auth shell. See ADR 0014.
class BankFinderController < ApplicationController
  skip_before_action :authorize_user
  skip_before_action :authenticate_user!
  skip_before_action :require_organization
  skip_before_action :log_active_user

  layout "essentials_auth"

  def show
    @near = params[:near].to_s.strip.first(100)
    return if @near.blank?

    @location = CensusLocation.locate(@near)
    @results = NearbyBanksQuery.call(@location) if @location.is_a?(CensusLocation::Point)
  end
end

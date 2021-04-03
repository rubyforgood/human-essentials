module Partners
  class RecertificationRequestsController < BaseController
    def create
      @partner = current_organization.partners.find(params[:id])

      svc = PartnerRequestRecertificationService.new(partner: @partner)
      svc.call

      if svc.errors.none?
        flash[:success] = "#{@partner.name} recertification successfully requested!"
      else
        flash[:error] = "#{@partner.name} failed to update partner records"
      end

      redirect_to partners_path
    end
  end
end


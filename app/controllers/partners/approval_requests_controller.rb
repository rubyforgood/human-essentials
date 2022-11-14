module Partners
  class ApprovalRequestsController < BaseController
    def create
      svc = Partners::RequestApprovalService.new(partner: current_partner)
      svc.call

      if svc.errors.none?
        flash[:success] = "You have submitted your details for approval."
      else
        flash[:error] = "Sorry we've encountered an issue. Please try requesting this approval again"
      end

      redirect_to partners_profile_path
    end
  end
end

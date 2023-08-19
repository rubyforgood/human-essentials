module Partners
  class ApprovalRequestsController < BaseController
    def create
      svc = Partners::RequestApprovalService.new(partner: current_partner)
      svc.call

      if svc.errors.none?
        flash[:success] = "You have submitted your details for approval."
      else
        flash[:error] = "Please edit your profile to resolve these issues:  ".concat(svc.partner.profile.errors.full_messages.join(".  "))
      end

      redirect_to partners_profile_path
    end
  end
end

module Requests
  class CancelationController < ApplicationController
    def new
      @request = Request.find(params[:request_id])
    end

    def create
      svc = RequestDestroyService.new(request_id: params[:request_id], reason: cancelation_params[:reason])

      svc.call

      if svc.errors.none?
        flash[:notice] = "Request #{params[:request_id]} has been removed!"
        redirect_to requests_path
      else
        errors = svc.errors.full_messages.join(", ")
        flash[:error] = "Request #{params[:request_id]} could not be removed because #{errors}"
        redirect_to new_request_cancelation_path(request_id: params[:request_id])
      end
    end

    private

    def cancelation_params
      params.require(:cancelation).permit(:reason)
    end
  end
end

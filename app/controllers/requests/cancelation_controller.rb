module Requests
  class CancelationController < ApplicationController
    # Migrated to the Ruby for Good design system (ADR 0011).
    layout "essentials_app"

    def new
      @request = Request.find(params[:request_id])
      @cancelation = Cancelation.new
    end

    def create
      @cancelation = Cancelation.new(reason: cancelation_params[:reason])

      # Retryable, so it re-renders and the reason the user typed survives -- unlike the service's
      # two failures below, which are states nothing they type can change. design.md: ask what the
      # user should do next and send them there.
      unless @cancelation.valid?
        @request = Request.find(params[:request_id])
        render :new, status: :unprocessable_content
        return
      end

      svc = RequestDestroyService.new(request_id: params[:request_id], reason: @cancelation.reason)

      svc.call

      if svc.errors.none?
        flash[:notice] = "Request #{params[:request_id]} has been cancelled."
        redirect_to requests_path
      else
        #
        # **Not back to the cancellation form.** It used to redirect there, which put the user in
        # front of a control that could never succeed while silently discarding the reason they had
        # written: `RequestDestroyService` fails only on states -- the request is already cancelled,
        # or it is gone -- and no amount of retyping changes either. Someone whose colleague
        # cancelled the request first would type their reason again and get the same error forever.
        #
        # The request's own page is where reality is: it shows the Cancelled status and whatever
        # reason was actually recorded. If the request cannot be found at all there is nothing to
        # show, so the list is the fallback.
        #
        # The flash stays. design.md: operational failure gets the flash, validation failure gets
        # the summary -- this is the former, and it was the destination that was wrong, not the
        # flash.
        flash[:error] = "Request #{params[:request_id]} could not be cancelled -- " \
                        "#{svc.errors.full_messages.to_sentence}."
        redirect_to(request_exists? ? request_path(params[:request_id]) : requests_path)
      end
    end

    private

    def cancelation_params
      params.require(:cancelation).permit(:reason)
    end

    # A cancelled request still has a page -- `requests#show` renders it and displays the Cancelled
    # status -- so "already cancelled" has somewhere to go. "We could not find it" does not, and
    # `request_path` on a missing id would answer the failure with a 404.
    def request_exists?
      Request.exists?(id: params[:request_id])
    end
  end
end

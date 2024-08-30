class Admin::AccountRequestsController < AdminController
  before_action :set_account_request, only: [:reject, :close]

  def index
    @open_account_requests = AccountRequest.requested.order('created_at DESC')
      .page(params[:open_page]).per(15)
    @closed_account_requests = AccountRequest.closed.order('updated_at DESC')
      .page(params[:close_page]).per(15)
  end

  def for_rejection
    @account_request = params[:token] && AccountRequest.get_by_identity_token(params[:token])
  end

  def reject
    @account_request.reject!(account_request_params[:rejection_reason])
    redirect_to admin_account_requests_path, notice: "Account request rejected!"
  end

  def close
    if @account_request.close!(account_request_params[:rejection_reason])
      redirect_to admin_account_requests_path, notice: "Account request closed!"
    else
      redirect_to admin_account_requests_path, error: "Account cannot be closed"
    end
  end

  def account_request_params
    params.require(:account_request).permit(:id, :rejection_reason)
  end

  private

  def set_account_request
    @account_request = AccountRequest.find(account_request_params[:id])
  end
end

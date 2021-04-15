class Admin::AccountRequestsController < AdminController
  def index
    @open_account_requests = AccountRequest.where(confirmed_at: nil).order('created_at DESC')
    @closed_account_requests = AccountRequest.where.not(confirmed_at: nil).order('confirmed_at DESC')
  end
end

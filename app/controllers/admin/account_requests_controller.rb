class Admin::AccountRequestsController < AdminController
  def index
    @open_account_requests = AccountRequest.where(confirmed_at: nil).order('created_at').reverse
    @closed_account_requests = AccountRequest.where.not(confirmed_at: nil).order('confirmed_at').reverse
  end
end

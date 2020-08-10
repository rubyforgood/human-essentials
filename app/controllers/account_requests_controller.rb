class AccountRequestsController < ApplicationController
  skip_before_action :authorize_user
  skip_before_action :authenticate_user!

  before_action :set_account_request_from_token, only: [:confirmation]

  layout 'devise'

  def confirmation
  end

  def new
    @account_request = AccountRequest.new
  end

  def create
    @account_request = AccountRequest.new(account_request_params)

    if @account_request.save
      redirect_to confirmation_account_requests_path(token: @account_request.identity_token), notice: 'Account request was successfully created.'
    else
      render :new
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_account_request_from_token
    @account_request = AccountRequest.find_by_identity_token(params[:token])
  end

  # Only allow a list of trusted parameters through.
  def account_request_params
    params.require(:account_request).permit(:email, :organization_name, :organization_website, :request_details)
  end
end

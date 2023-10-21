class AccountRequestsController < ApplicationController
  skip_before_action :authorize_user
  skip_before_action :authenticate_user!

  before_action :set_account_request_from_token, only: [:received, :confirmation, :confirm]

  layout 'devise'

  def received; end

  def confirmation; end

  def confirm
    @account_request.confirm!
  end

  def invalid_token; end

  def new
    @account_request = AccountRequest.new
  end

  def create
    @account_request = AccountRequest.new(account_request_params)
    @bank_selected = true

    if !verify_recaptcha(model: @account_request)
      flash[:alert] = "Invalid captcha submission"
      render :new
    elsif @account_request.save
      AccountRequestMailer.confirmation(account_request_id: @account_request.id).deliver_later

      redirect_to received_account_requests_path(token: @account_request.identity_token),
                  notice: 'Account request was successfully created.'
    else
      render :new
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_account_request_from_token
    @account_request = AccountRequest.get_by_identity_token(params[:token])

    # Use confirmation timestamp instead
    if @account_request.nil? || @account_request.confirmed? || @account_request.processed?
      redirect_to invalid_token_account_requests_path(token: params[:token])
      return
    end

    @account_request
  end

  # Only allow a list of trusted parameters through.
  def account_request_params
    params.require(:account_request).permit(:name, :email, :organization_name, :organization_website, :request_details, :ndbn_member_id)
  end
end

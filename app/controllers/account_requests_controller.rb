class AccountRequestsController < ApplicationController
  skip_before_action :authorize_user
  skip_before_action :authenticate_user!

  before_action :set_account_request_from_token, only: [:confirmation, :confirm, :confirm_last]

  layout 'devise'

  def confirmation
    # Maybe better would be the word 'received'
  end

  def confirm
  end

  def confirm_last
    # Show a different message if they were already confirmed.
    #
    # Send email to us with a link that lets us register them via
    # a link.
  end

  def invalid_token
  end

  def new
    @account_request = AccountRequest.new
  end

  def create
    @account_request = AccountRequest.new(account_request_params)

    if @account_request.save
      # Check that this works later.
      AccountRequestMailer.confirmation(account_request_id: @account_request.id).deliver_now

      redirect_to confirmation_account_requests_path(token: @account_request.identity_token), notice: 'Account request was successfully created.'
    else
      render :new
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_account_request_from_token
    @account_request = AccountRequest.find_by_identity_token(params[:token])

    if @account_request.nil?
      redirect_to invalid_token_account_requests_path(token: params[:token])
      return
    end

    @account_request
  end

  # Only allow a list of trusted parameters through.
  def account_request_params
    params.require(:account_request).permit(:email, :organization_name, :organization_website, :request_details)
  end
end

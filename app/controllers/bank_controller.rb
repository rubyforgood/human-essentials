class BankController < ApplicationController
  def index
    @bank = Bank.all
  end

  def show
    @bank = Bank.find(params[:id])
  end

  def new
    @bank = Bank.new
  end

  def edit
    @bank = Bank.find(params[:id])
  end

  def create
    @bank = Bank.new(bank_params)

    if @bank.save
      redirect_to @bank
    else
      render 'new'
    end
  end

  def update
    @bank = Bank.find(params[:id])

    if @bank.update(bank_params)
      redirect_to @bank
    else
      render 'edit'
    end
  end

  def destroy
    @bank = Bank.find(params[:id])
    @bank.destroy

    redirect_to bank_index_path
  end


  def update_email_notification
    @bank = Bank.find(params[:id])
    @bank.update(opt_in_email_notification: params[:opt_in_email_notification])

    if @bank.opt_in_email_notification?
      @partner_request = @bank.partner_requests.last
      BankMailer.request_notification(@bank, @partner_request).deliver_now if @partner_request
    end

    redirect_to @bank, notice: 'Email notification preference updated successfully.'
  end


  private
    def bank_params
      params.require(:bank).permit(:name, :email, :phone, :address)
    end
end

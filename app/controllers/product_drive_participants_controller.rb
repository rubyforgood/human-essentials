# Provides (nearly) full CRUD for ProductDriveParticipants, which are the community entities that yield inventory during
# a Product Drive.
class ProductDriveParticipantsController < ApplicationController
  include Importable

  # TODO: Should there be a :destroy action for this?

  def index
    @product_drive_participants = current_organization.product_drive_participants.includes(:donations).all.order(:business_name)

    respond_to do |format|
      format.html
      format.csv { send_data ProductDriveParticipant.generate_csv(@product_drive_participants), filename: "ProductDriveParticipants-#{Time.zone.today}.csv" }
    end
  end

  def create
    @product_drive_participant = current_organization.product_drive_participants.new(product_drive_participant_params.merge(organization: current_organization))
    respond_to do |format|
      if @product_drive_participant.save
        format.html { redirect_to product_drive_participants_path, notice: "New product drive participant added!" }
        format.js
      else
        flash[:error] = "Something didn't work quite right -- try again?"
        format.html { render action: :new }
        format.js { render template: "product_drive_participants/new_modal" }
      end
    end
  end

  def new
    @product_drive_participant = current_organization.product_drive_participants.new
    if request.xhr?
      respond_to do |format|
        format.js { render template: "product_drive_participants/new_modal" }
      end
    end
  end

  def edit
    @product_drive_participant = current_organization.product_drive_participants.find(params[:id])
  end

  def show
    @product_drive_participant = current_organization.product_drive_participants.includes(:donations).find(params[:id])
  end

  def update
    @product_drive_participant = current_organization.product_drive_participants.find(params[:id])
    if @product_drive_participant.update(product_drive_participant_params)
      redirect_to product_drive_participants_path, notice: "#{@product_drive_participant.contact_name} updated!"

    else
      flash[:error] = "Something didn't work quite right -- try again?"
      render action: :edit
    end
  end

  private

  def product_drive_participant_params
    params.require(:product_drive_participant)
          .permit(:contact_name, :phone, :email, :business_name, :address, :comment)
  end

  helper_method \
    def filter_params
    {}
  end
end

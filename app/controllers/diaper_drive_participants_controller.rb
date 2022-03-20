# Provides (nearly) full CRUD for DiaperDriveParticipants, which are the community entities that yield inventory during
# a Product Drive.
class DiaperDriveParticipantsController < ApplicationController
  include Importable

  # TODO: Should there be a :destroy action for this?

  def index
    @diaper_drive_participants = current_organization.diaper_drive_participants.includes(:donations).all.order(:business_name)

    respond_to do |format|
      format.html
      format.csv { send_data DiaperDriveParticipant.generate_csv(@diaper_drive_participants), filename: "DiaperDriveParticipants-#{Time.zone.today}.csv" }
    end
  end

  def create
    @diaper_drive_participant = current_organization.diaper_drive_participants.new(diaper_drive_participant_params.merge(organization: current_organization))
    respond_to do |format|
      if @diaper_drive_participant.save
        format.html { redirect_to diaper_drive_participants_path, notice: "New product drive participant added!" }
        format.js
      else
        flash[:error] = "Something didn't work quite right -- try again?"
        format.html { render action: :new }
        format.js { render template: "diaper_drive_participants/new_modal" }
      end
    end
  end

  def new
    @diaper_drive_participant = current_organization.diaper_drive_participants.new
    if request.xhr?
      respond_to do |format|
        format.js { render template: "diaper_drive_participants/new_modal" }
      end
    end
  end

  def edit
    @diaper_drive_participant = current_organization.diaper_drive_participants.find(params[:id])
  end

  def show
    @diaper_drive_participant = current_organization.diaper_drive_participants.includes(:donations).find(params[:id])
  end

  def update
    @diaper_drive_participant = current_organization.diaper_drive_participants.find(params[:id])
    if @diaper_drive_participant.update(diaper_drive_participant_params)
      redirect_to diaper_drive_participants_path, notice: "#{@diaper_drive_participant.contact_name} updated!"

    else
      flash[:error] = "Something didn't work quite right -- try again?"
      render action: :edit
    end
  end

  private

  def diaper_drive_participant_params
    params.require(:diaper_drive_participant)
          .permit(:contact_name, :phone, :email, :business_name, :address)
  end

  helper_method \
    def filter_params
    {}
  end
end

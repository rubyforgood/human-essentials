class DiaperDriveParticipantsController < ApplicationController
  def index
    @diaper_drive_participants = current_organization.diaper_drive_participants.includes(:donations).all.order(:name)
  end

  def create
    @diaper_drive_participant = current_organization.diaper_drive_participants.new(diaper_drive_participant_params.merge(organization: current_organization))
    respond_to do |format|
      if @diaper_drive_participant.save
        format.html { redirect_to diaper_drive_participants_path, notice: "New diaper drive participant added!" }
        format.js
      else
        flash[:error] = "Something didn't work quite right -- try again?"
        format.html { render action: :new }
        format.js { render template: "diaper_drive_participants/new_modal.js.erb" }
      end
    end
  end

  def new
    @diaper_drive_participant = current_organization.diaper_drive_participants.new
    if request.xhr?
      respond_to do |format|
        format.js { render template: "diaper_drive_participants/new_modal.js.erb" }
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
      redirect_to diaper_drive_participants_path, notice: "#{@diaper_drive_participant.name} updated!"
    else
      flash[:error] = "Something didn't work quite right -- try again?"
      render action: :edit
    end
  end

  def import_csv
    if params[:file].nil?
      redirect_back(fallback_location: diaper_drive_participants_path(organization_id: current_organization))
      flash[:error] = "No file was attached!"
    else
      filepath = params[:file].read
      DiaperDriveParticipant.import_csv(filepath, current_organization.id)
      flash[:notice] = "Diaper drive participants were imported successfully!"
      redirect_back(fallback_location: diaper_drive_participants_path(organization_id: current_organization))
    end
  end

  private

  def diaper_drive_participant_params
    params.require(:diaper_drive_participant)
          .permit(:name, :phone, :email, :business_name, :address)
  end
end

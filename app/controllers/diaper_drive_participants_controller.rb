class DiaperDriveParticipantsController < ApplicationController
  def index
    @diaper_drive_participants = current_organization.diaper_drive_participants.includes(:donations).all.order(:name)
  end

  def create
    @diaper_drive_participant = current_organization.diaper_drive_participants.new(diaper_drive_participant_params.merge(organization: current_organization))
    if (@diaper_drive_participant.save)
      redirect_to diaper_drive_participants_path, notice: "New diaper drive participant added!"
    else
      flash[:notice] = "Something didn't work quite right -- try again?"
      render action: :new
    end

  end

  def new
    @diaper_drive_participant = current_organization.diaper_drive_participants.new
  end

  def edit
    @diaper_drive_participant = current_organization.diaper_drive_participants.find(params[:id])
  end

  def show
    @diaper_drive_participant = current_organization.diaper_drive_participants.includes(:donations).find(params[:id])
  end

  def update
    @diaper_drive_participant = current_organization.diaper_drive_participants.find(params[:id])
    @diaper_drive_participant.update_attributes(diaper_drive_participant_params)
    redirect_to diaper_drive_participants_path, notice: "#{@diaper_drive_participant.name} updated!"
  end

private
  def diaper_drive_participant_params
    params.require(:diaper_drive_participant).permit(:name, :phone, :email)
  end
end

class DiaperDriveParticipantsController < ApplicationController
  def index
    @diaper_drive_participants = DiaperDriveParticipant.includes(:donations).all
  end

  def create
    @diaper_drive_participant = DiaperDriveParticipant.new(diaper_drive_participant_params.merge(organization: current_organization))
    if (@diaper_drive_participant.save)
      redirect_to @diaper_drive_participant, notice: "New diaper drive participant added!"
    else
      flash[:notice] = "Something didn't work quite right -- try again?"
      render action: :new
    end
    
  end

  def new
    @diaper_drive_participant = DiaperDriveParticipant.new
  end

  def edit
    @diaper_drive_participant = DiaperDriveParticipant.find(params[:id])
  end

  def show
    @diaper_drive_participant = DiaperDriveParticipant.includes(:donations).find(params[:id])
  end

  def update
    @diaper_drive_participant = DiaperDriveParticipant.find(params[:id])
    @diaper_drive_participant.update_attributes(diaper_drive_participant_params)
    redirect_to @diaper_drive_participant, notice: "#{@diaper_drive_participant.name} updated!"
  end

private
  def diaper_drive_participant_params
    params.require(:diaper_drive_participant).permit(:name, :phone, :email)
  end
end

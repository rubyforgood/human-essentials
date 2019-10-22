class DiaperDrivesController < ApplicationController
  include Importable
  before_action :set_diaper_drive, only: [:show, :edit, :update, :destroy]

  def index
    @diaper_drives = current_organization.diaper_drives.includes(:donations).all.order(:name)
  end

  def create
    @diaper_drive = current_organization.diaper_drives.new(diaper_drive_params.merge(organization: current_organization))
    respond_to do |format|
      if @diaper_drive.save
        format.html { redirect_to diaper_drives_path, notice: "New diaper drive added!" }
        format.js
      else
        flash[:error] = "Something didn't work quite right -- try again?"
        format.html { render action: :new }
        format.js { render template: "diaper_drives/new_modal.js.erb" }
      end
    end
  end

  def new
    @diaper_drive = current_organization.diaper_drives.new
    if request.xhr?
      respond_to do |format|
        format.js { render template: "diaper_drives/new_modal.js.erb" }
      end
    end
  end

  def edit
    @diaper_drive = current_organization.diaper_drives.find(params[:id])
  end

  def show
    @diaper_drive = current_organization.diaper_drives.includes(:donations).find(params[:id])
  end

  def update
    @diaper_drive = current_organization.diaper_drives.find(params[:id])
    if @diaper_drive.update(diaper_drive_params)
      redirect_to diaper_drives_path, notice: "#{@diaper_drive.contact_name} updated!"

    else
      flash[:error] = "Something didn't work quite right -- try again?"
      render action: :edit
    end
  end

  def destroy
    @diaper_drive.destroy
    respond_to do |format|
      format.html { redirect_to diaper_drives_url, notice: 'Diaper drive was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_diaper_drive
    @diaper_drive = DiaperDrive.find(params[:id])
  end

  def diaper_drive_params
    params.require(:diaper_drive)
          .permit(:name, :start_date, :end_date)
  end
end

class DiaperDrivesController < ApplicationController
  before_action :set_diaper_drive, only: [:show, :edit, :update, :destroy]

  # GET /diaper_drives
  # GET /diaper_drives.json
  def index
    @diaper_drives = DiaperDrive.all
  end

  # GET /diaper_drives/1
  # GET /diaper_drives/1.json
  def show; end

  # GET /diaper_drives/new
  def new
    @diaper_drive = DiaperDrive.new
  end

  # GET /diaper_drives/1/edit
  def edit; end

  # POST /diaper_drives
  # POST /diaper_drives.json
  def create
    @diaper_drive = DiaperDrive.new(diaper_drive_params)

    respond_to do |format|
      if @diaper_drive.save
        format.html { redirect_to @diaper_drive, notice: 'Diaper drive was successfully created.' }
        format.json { render :show, status: :created, location: @diaper_drive }
      else
        format.html { render :new }
        format.json { render json: @diaper_drive.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /diaper_drives/1
  # PATCH/PUT /diaper_drives/1.json
  def update
    respond_to do |format|
      if @diaper_drive.update(diaper_drive_params)
        format.html { redirect_to @diaper_drive, notice: 'Diaper drive was successfully updated.' }
        format.json { render :show, status: :ok, location: @diaper_drive }
      else
        format.html { render :edit }
        format.json { render json: @diaper_drive.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /diaper_drives/1
  # DELETE /diaper_drives/1.json
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

  # Never trust parameters from the scary internet, only allow the white list through.
  def diaper_drive_params
    params.require(:diaper_drive).permit(:name, :start_date, :end_date)
  end
end

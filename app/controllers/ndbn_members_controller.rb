class NDBNMembersController < ApplicationController
  before_action :authorize_ndbn

  layout :set_layout

  def index
  end

  def create
    service = SyncNDBNMembers.new(file_params)
    service.call

    if service.errors.none?
      redirect_to ndbn_members_path, notice: "NDBN Members have been updated!"
    else
      redirect_to ndbn_members_path, error: service.errors.full_messages
    end
  end

  private

  def file_params
    params[:member_file]&.tempfile
  end

  def set_layout
    current_partner ? "partners/application" : "application"
  end

  def ndbn_members
    @ndbn_members ||= NDBNMember.all
  end
  helper_method :ndbn_members
end

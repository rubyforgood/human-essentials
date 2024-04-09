class Admin::NDBNMembersController < AdminController
  def index
  end

  def upload_csv
    service = SyncNDBNMembers.new(file_params)
    service.call

    if service.errors.none?
      redirect_to admin_ndbn_members_path, notice: "NDBN Members have been updated!"
    else
      redirect_to admin_ndbn_members_path, error: service.errors.full_messages.join("\n")
    end
  end

  private

  def file_params
    params[:member_file]&.tempfile
  end

  def ndbn_members
    @ndbn_members ||= NDBNMember.all
  end
  helper_method :ndbn_members
end

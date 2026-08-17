class Admin::NDBNMembersController < AdminController
  # Migrated to the Ruby for Good design system (ADR 0011).
  layout "essentials_app"

  def index
  end

  def upload_csv
    errors = SyncNDBNMembers.upload(file_params)

    if errors.empty?
      redirect_to admin_ndbn_members_path, notice: "NDBN Members have been updated!"
    else
      redirect_to admin_ndbn_members_path, error: errors.join("\n")
    end
  end

  private

  def file_params
    params[:member_file]&.tempfile
  end

  def ndbn_members
    @ndbn_members ||= NDBNMember.all.order(:ndbn_member_id)
  end
  helper_method :ndbn_members
end
